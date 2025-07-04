require 'net/http'
require 'json'
require 'uri'

class GoogleMapsService
  GEOCODE_BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json'
  PLACES_BASE_URL = 'https://maps.googleapis.com/maps/api/place'
  
  class << self
    def geocode(address)
      return { success: false, error: 'No address provided' } if address.blank?
      
      params = {
        address: address,
        key: api_key
      }
      
      uri = URI(GEOCODE_BASE_URL)
      uri.query = URI.encode_www_form(params)
      
      begin
        response = Net::HTTP.get_response(uri)
        data = JSON.parse(response.body)
        
        if data['status'] == 'OK' && data['results'].any?
          result = data['results'].first
          location = result['geometry']['location']
          
          {
            success: true,
            latitude: location['lat'],
            longitude: location['lng'],
            formatted_address: result['formatted_address'],
            place_id: result['place_id'],
            address_components: result['address_components'],
            viewport: result['geometry']['viewport'],
            bounds: result['geometry']['bounds']
          }
        else
          {
            success: false,
            error: data['error_message'] || "No results found for: #{address}",
            status: data['status']
          }
        end
      rescue => e
        {
          success: false,
          error: "Geocoding failed: #{e.message}"
        }
      end
    end
    
    def reverse_geocode(latitude, longitude)
      return { success: false, error: 'Invalid coordinates' } if latitude.nil? || longitude.nil?
      
      params = {
        latlng: "#{latitude},#{longitude}",
        key: api_key
      }
      
      uri = URI(GEOCODE_BASE_URL)
      uri.query = URI.encode_www_form(params)
      
      begin
        response = Net::HTTP.get_response(uri)
        data = JSON.parse(response.body)
        
        if data['status'] == 'OK' && data['results'].any?
          result = data['results'].first
          
          {
            success: true,
            formatted_address: result['formatted_address'],
            place_id: result['place_id'],
            address_components: result['address_components'],
            results: data['results'].map { |r| 
              {
                formatted_address: r['formatted_address'],
                types: r['types'],
                place_id: r['place_id']
              }
            }
          }
        else
          {
            success: false,
            error: data['error_message'] || 'No address found for coordinates',
            status: data['status']
          }
        end
      rescue => e
        {
          success: false,
          error: "Reverse geocoding failed: #{e.message}"
        }
      end
    end
    
    def search_nearby_properties(latitude, longitude, radius = 1000)
      # Search for nearby properties/addresses
      params = {
        location: "#{latitude},#{longitude}",
        radius: radius,
        type: 'premise|street_address',
        key: api_key
      }
      
      uri = URI("#{PLACES_BASE_URL}/nearbysearch/json")
      uri.query = URI.encode_www_form(params)
      
      begin
        response = Net::HTTP.get_response(uri)
        data = JSON.parse(response.body)
        
        if data['status'] == 'OK'
          {
            success: true,
            results: data['results'].map { |place|
              {
                place_id: place['place_id'],
                name: place['name'],
                vicinity: place['vicinity'],
                location: place['geometry']['location'],
                types: place['types']
              }
            }
          }
        else
          {
            success: false,
            error: data['error_message'] || 'No nearby properties found',
            status: data['status']
          }
        end
      rescue => e
        {
          success: false,
          error: "Nearby search failed: #{e.message}"
        }
      end
    end
    
    def get_place_details(place_id)
      return { success: false, error: 'No place_id provided' } if place_id.blank?
      
      params = {
        place_id: place_id,
        fields: 'formatted_address,geometry,name,address_components,types',
        key: api_key
      }
      
      uri = URI("#{PLACES_BASE_URL}/details/json")
      uri.query = URI.encode_www_form(params)
      
      begin
        response = Net::HTTP.get_response(uri)
        data = JSON.parse(response.body)
        
        if data['status'] == 'OK' && data['result']
          result = data['result']
          
          {
            success: true,
            name: result['name'],
            formatted_address: result['formatted_address'],
            location: result['geometry']['location'],
            viewport: result['geometry']['viewport'],
            address_components: result['address_components'],
            types: result['types']
          }
        else
          {
            success: false,
            error: data['error_message'] || 'Place not found',
            status: data['status']
          }
        end
      rescue => e
        {
          success: false,
          error: "Place details failed: #{e.message}"
        }
      end
    end
    
    private
    
    def api_key
      Rails.application.config.google_maps[:api_key] || ENV['GOOGLE_MAPS_API_KEY']
    end
  end
end 