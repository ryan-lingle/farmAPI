module Api
  module V1
    class LocationsController < ApiController
      before_action :set_location, only: [ :show, :update, :destroy ]

      def index
        locations = Location.all
        render json: LocationSerializer.new(locations).serializable_hash
      end

      def show
        render json: LocationSerializer.new(@location).serializable_hash
      end

      def create
        location = Location.new(location_params)
        if location.save
          render json: LocationSerializer.new(location).serializable_hash, status: :created
        else
          render_jsonapi_errors(location.errors, status: :unprocessable_entity)
        end
      end

      def update
        if @location.update(location_params)
          render json: LocationSerializer.new(@location).serializable_hash
        else
          render_jsonapi_errors(@location.errors, status: :unprocessable_entity)
        end
      end

      def destroy
        @location.archive!
        head :no_content
      end

      private

      def set_location
        @location = Location.find(params[:id])
      end

      def location_params
        if params[:_jsonapi].present?
          base_params = params.require(:_jsonapi).require(:data).require(:attributes)
        elsif params[:data].present?
          base_params = params.require(:data).require(:attributes)
        else
          base_params = params.require(:location)
        end

        permitted = base_params.permit(:name, :status, :notes, :location_type, :archived_at)

        if base_params[:geometry].is_a?(Array)
          permitted[:geometry] = base_params[:geometry].map do |point|
            point.permit(:latitude, :longitude)
          end
        elsif base_params[:geometry].is_a?(ActionController::Parameters)
          permitted[:geometry] = base_params[:geometry].permit(:latitude, :longitude, :radius)
        end

        permitted
      end
    end
  end
end
