module Api
  module V1
    class LogsController < ApiController
      before_action :set_log_type
      before_action :set_log, only: [ :show, :update, :destroy ]

      def index
        @logs = Log.where(log_type: @log_type)
        @logs = @logs.where(status: params[:filter][:status]) if params.dig(:filter, :status)

        # Handle pagination - support both page[number] and page formats
        if params[:page].is_a?(Hash) || params[:page].is_a?(ActionController::Parameters)
          page_number = (params[:page][:number] || 1).to_i
          page_size = (params[:page][:size] || 20).to_i
        else
          page_number = (params[:page] || 1).to_i
          page_size = (params[:per_page] || 20).to_i
        end

        @logs = @logs.page(page_number).per(page_size)

        render_jsonapi(@logs)
      end

      def show
        render_jsonapi(@log)
      end

      def create
        @log = Log.new(log_params)
        @log.log_type = @log_type

        if @log.save
          # Handle role-based asset associations
          create_asset_associations

          # If log is created as done, execute completion logic
          if @log.status == "done"
            @log.execute_movement! if @log.movement_log?
            @log.process_harvest! if @log.harvest_log?
            @log.emit_facts!
          end
          render_jsonapi(@log)
        else
          render_jsonapi_errors(@log.errors)
        end
      end

      def update
        was_pending = @log.pending?
        becoming_done = log_params[:status] == "done"

        if @log.update(log_params)
          # Trigger completion logic when status changes to done
          if was_pending && becoming_done
            @log.execute_movement! if @log.movement_log?
            @log.process_harvest! if @log.harvest_log?
            @log.emit_facts!
          end
          render_jsonapi(@log)
        else
          render_jsonapi_errors(@log.errors)
        end
      end

      def destroy
        @log.destroy
        head :no_content
      end

      private

      def set_log_type
        @log_type = params[:log_type] || "log"
      end

      def set_log
        @log = Log.where(log_type: @log_type).find(params[:id])
      end

      def create_asset_associations
        # Create role-based asset associations
        @source_asset_ids&.each do |asset_id|
          AssetLog.create!(log: @log, asset_id: asset_id, role: 'source')
        end

        @moved_asset_ids&.each do |asset_id|
          AssetLog.create!(log: @log, asset_id: asset_id, role: 'moved')
        end

        @output_asset_ids&.each do |asset_id|
          AssetLog.create!(log: @log, asset_id: asset_id, role: 'output')
        end

        @subject_asset_ids&.each do |asset_id|
          AssetLog.create!(log: @log, asset_id: asset_id, role: 'subject')
        end
      end

      def log_params
        # Handle jsonapi-rails _jsonapi parameter
        if params[:_jsonapi].present?
          attributes = params.require(:_jsonapi).require(:data).require(:attributes)
        elsif params[:data].present?
          attributes = params.require(:data).require(:attributes)
        else
          attributes = params
        end

        # Permit common log attributes and type-specific ones
        permitted = attributes.permit(
          :name, :status, :notes, :timestamp,
          :activity_type, :crop_type,
          :from_location_id, :to_location_id, :moved_at,
          quantities: [ :measure, :value, :unit, :label ],
          quantities_attributes: [ :measure, :value, :unit, :label ],
          asset_ids: [],
          source_asset_ids: [],
          moved_asset_ids: [],
          output_asset_ids: [],
          subject_asset_ids: []
        )

        # Handle quantities (support both 'quantities' and 'quantities_attributes' keys)
        if permitted[:quantities].present?
          permitted[:quantities_attributes] = permitted.delete(:quantities)
        end

        # Store role-based asset IDs for later processing
        @source_asset_ids = permitted.delete(:source_asset_ids)
        @moved_asset_ids = permitted.delete(:moved_asset_ids)
        @output_asset_ids = permitted.delete(:output_asset_ids)
        @subject_asset_ids = permitted.delete(:subject_asset_ids)

        permitted
      end
    end
  end
end
