module Api
  module V1
    class AssetsController < ApiController
      before_action :set_asset_type
      before_action :set_asset, only: [ :show, :update, :destroy ]

      def index
        @assets = Asset.where(asset_type: @asset_type)
        @assets = @assets.where(status: params[:filter][:status]) if params.dig(:filter, :status)

        # Handle pagination - support both page[number] and page formats
        page_number = (params.dig(:page, :number) || params[:page] || 1).to_i
        page_size = (params.dig(:page, :size) || params[:per_page] || 20).to_i

        @assets = @assets.page(page_number).per(page_size)

        render_jsonapi(@assets)
      end

      def show
        render_jsonapi(@asset)
      end

      def create
        @asset = Asset.new(asset_params)
        @asset.asset_type = @asset_type

        if @asset.save
          render_jsonapi(@asset)
        else
          render_jsonapi_errors(@asset.errors)
        end
      end

      def update
        if @asset.update(asset_params)
          render_jsonapi(@asset)
        else
          render_jsonapi_errors(@asset.errors)
        end
      end

      def destroy
        @asset.destroy
        head :no_content
      end

      private

      def set_asset_type
        @asset_type = params[:asset_type] || "asset"
      end

      def set_asset
        @asset = Asset.where(asset_type: @asset_type).find(params[:id])
      end

      def asset_params
        # Handle jsonapi-rails _jsonapi parameter
        if params[:_jsonapi].present?
          params.require(:_jsonapi).require(:data).require(:attributes).permit(
            :name, :status, :notes, :is_location, :is_fixed
          )
        elsif params[:data].present?
          params.require(:data).require(:attributes).permit(
            :name, :status, :notes, :is_location, :is_fixed
          )
        else
          params.permit(:name, :status, :notes, :is_location, :is_fixed)
        end
      end
    end
  end
end
