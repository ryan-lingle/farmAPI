module Api
  module V1
    class PropertiesController < BaseController
      before_action :set_property, only: [:show, :update, :destroy]
      
      def index
        properties = Location.all
        properties = properties.where("notes LIKE ?", "%property_type%") if params[:only_properties]
        properties = properties.where(location_type: params[:location_type]) if params[:location_type]
        
        render json: LocationSerializer.new(properties).serializable_hash
      end
      
      def show
        render json: LocationSerializer.new(@property).serializable_hash
      end
      
      def create_from_address
        address = params[:address]
        property_type = params[:property_type] || 'farm'
        location_type = params[:location_type] || 'polygon'
        
        if address.blank?
          render_jsonapi_errors({ address: ['Address is required'] })
          return
        end
        
        # Geocode the address
        geocode_result = GoogleMapsService.geocode(address)
        
        if geocode_result[:success]
          # Create the property location
          property = Location.create_from_geocode_result(
            geocode_result,
            location_type: location_type,
            property_type: property_type
          )
          
          render json: {
            data: {
              type: 'property',
              id: property.id,
              attributes: {
                name: property.name,
                location_type: property.location_type,
                geometry: property.geometry,
                metadata: property.metadata,
                area_in_acres: property.area_in_acres,
                center_point: property.center_point
              }
            }
          }, status: :created
        else
          render_jsonapi_errors({ geocoding: [geocode_result[:error]] })
        end
      end
      
      def update_boundaries
        if params[:geometry].blank?
          render_jsonapi_errors({ geometry: ['Geometry is required'] })
          return
        end
        
        @property.geometry = params[:geometry]
        
        if @property.save
          render json: {
            data: {
              type: 'property',
              id: @property.id,
              attributes: {
                name: @property.name,
                location_type: @property.location_type,
                geometry: @property.geometry,
                metadata: @property.metadata,
                area_in_acres: @property.area_in_acres,
                center_point: @property.center_point
              }
            }
          }
        else
          render_jsonapi_errors(@property.errors)
        end
      end
      
      def search_nearby
        lat = params[:latitude]&.to_f
        lon = params[:longitude]&.to_f
        radius = params[:radius]&.to_f || 5.0 # km
        
        if lat.nil? || lon.nil?
          render_jsonapi_errors({ coordinates: ['Latitude and longitude are required'] })
          return
        end
        
        # Simple distance-based search
        # In production, you'd want to use PostGIS or similar
        properties = Location.all.select do |location|
          center = location.center_point
          next false unless center
          
          # Haversine formula for distance
          lat1 = lat * Math::PI / 180
          lat2 = center['latitude'] * Math::PI / 180
          dlat = (center['latitude'] - lat) * Math::PI / 180
          dlon = (center['longitude'] - lon) * Math::PI / 180
          
          a = Math.sin(dlat/2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dlon/2)**2
          c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
          distance = 6371 * c # Earth radius in km
          
          distance <= radius
        end
        
        render json: LocationSerializer.new(properties).serializable_hash
      end
      
      def link_to_asset
        asset_id = params[:asset_id]
        asset_type = params[:asset_type] || 'land'
        
        # Find the asset
        asset = case asset_type
        when 'land'
          LandAsset.find_by(id: asset_id)
        else
          Asset.find_by(id: asset_id)
        end
        
        if asset.nil?
          render_jsonapi_errors({ asset: ['Asset not found'] })
          return
        end
        
        # Update property metadata to link to asset
        metadata = @property.metadata
        metadata['linked_asset_id'] = asset.id
        metadata['linked_asset_type'] = asset_type
        @property.metadata = metadata
        
        if @property.save
          render json: {
            data: {
              type: 'property',
              id: @property.id,
              attributes: {
                name: @property.name,
                linked_asset: {
                  id: asset.id,
                  type: asset_type,
                  name: asset.name
                }
              }
            }
          }
        else
          render_jsonapi_errors(@property.errors)
        end
      end
      
      private
      
      def set_property
        @property = Location.find(params[:id])
      end
      
      def property_params
        params.require(:property).permit(:name, :location_type, :notes, 
          geometry: {}, metadata: {})
      end
    end
  end
end 