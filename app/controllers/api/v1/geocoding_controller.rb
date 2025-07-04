module Api
  module V1
    class GeocodingController < BaseController
      def geocode
        address = params[:address]
        
        if address.blank?
          render_jsonapi_errors({ address: ['Address is required'] })
          return
        end
        
        result = GoogleMapsService.geocode(address)
        
        if result[:success]
          render json: {
            data: {
              type: 'geocode_result',
              attributes: {
                latitude: result[:latitude],
                longitude: result[:longitude],
                formatted_address: result[:formatted_address],
                place_id: result[:place_id],
                address_components: result[:address_components],
                viewport: result[:viewport],
                bounds: result[:bounds]
              }
            }
          }
        else
          render_jsonapi_errors({ geocoding: [result[:error]] })
        end
      end
      
      def reverse_geocode
        lat = params[:latitude]&.to_f
        lon = params[:longitude]&.to_f
        
        if lat.nil? || lon.nil?
          render_jsonapi_errors({ coordinates: ['Latitude and longitude are required'] })
          return
        end
        
        result = GoogleMapsService.reverse_geocode(lat, lon)
        
        if result[:success]
          render json: {
            data: {
              type: 'reverse_geocode_result',
              attributes: {
                formatted_address: result[:formatted_address],
                place_id: result[:place_id],
                address_components: result[:address_components],
                results: result[:results]
              }
            }
          }
        else
          render_jsonapi_errors({ geocoding: [result[:error]] })
        end
      end
      
      def search_nearby
        lat = params[:latitude]&.to_f
        lon = params[:longitude]&.to_f
        radius = params[:radius]&.to_i || 1000
        
        if lat.nil? || lon.nil?
          render_jsonapi_errors({ coordinates: ['Latitude and longitude are required'] })
          return
        end
        
        result = GoogleMapsService.search_nearby_properties(lat, lon, radius)
        
        if result[:success]
          render json: {
            data: result[:results].map { |place|
              {
                type: 'nearby_property',
                id: place[:place_id],
                attributes: {
                  name: place[:name],
                  vicinity: place[:vicinity],
                  location: place[:location],
                  types: place[:types]
                }
              }
            }
          }
        else
          render_jsonapi_errors({ search: [result[:error]] })
        end
      end
      
      def place_details
        place_id = params[:place_id]
        
        if place_id.blank?
          render_jsonapi_errors({ place_id: ['Place ID is required'] })
          return
        end
        
        result = GoogleMapsService.get_place_details(place_id)
        
        if result[:success]
          render json: {
            data: {
              type: 'place_details',
              id: place_id,
              attributes: {
                name: result[:name],
                formatted_address: result[:formatted_address],
                location: result[:location],
                viewport: result[:viewport],
                address_components: result[:address_components],
                types: result[:types]
              }
            }
          }
        else
          render_jsonapi_errors({ place: [result[:error]] })
        end
      end
    end
  end
end 