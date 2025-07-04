module Api
  module V1
    class LogsController < ApiController
      before_action :set_log_type
      before_action :set_log, only: [ :show, :update, :destroy ]

      def index
        @logs = log_class.all
        @logs = @logs.where(status: params[:filter][:status]) if params.dig(:filter, :status)

        # Handle pagination - support both page[number] and page formats
        page_number = (params.dig(:page, :number) || params[:page] || 1).to_i
        page_size = (params.dig(:page, :size) || params[:per_page] || 20).to_i

        @logs = @logs.page(page_number).per(page_size)

        render_jsonapi(@logs)
      end

      def show
        render_jsonapi(@log)
      end

      def create
        @log = log_class.new(log_params)
        @log.log_type = @log_type

        if @log.save
          render_jsonapi(@log)
        else
          render_jsonapi_errors(@log.errors)
        end
      end

      def update
        if @log.update(log_params)
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

      def log_class
        case @log_type
        when "harvest"
          HarvestLog
        when "activity"
          ActivityLog
        else
          Log
        end
      end

      def set_log
        @log = log_class.find(params[:id])
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
          quantities: [ :measure, :value, :unit, :label ],
          asset_ids: []
        )

        # Handle quantities if present
        if permitted[:quantities].present?
          permitted[:quantities_attributes] = permitted.delete(:quantities)
        end

        permitted
      end
    end
  end
end
