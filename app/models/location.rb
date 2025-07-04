# app/models/location.rb
class Location < ApplicationRecord
  validates :name, presence: true
  validates :location_type, inclusion: { in: %w[point polygon],
    message: "%{value} is not a valid location_type" }

  validate :validate_geometry

  # Additional attributes that can be stored in the notes field as JSON
  # like address, place_id, property_type, etc.
  def metadata
    return {} if notes.blank?
    JSON.parse(notes) rescue {}
  end
  
  def metadata=(value)
    self.notes = value.to_json
  end
  
  # Helper methods for property management
  def property?
    metadata['property_type'].present?
  end
  
  def address
    metadata['address'] || metadata['formatted_address']
  end
  
  def place_id
    metadata['place_id']
  end
  
  def property_type
    metadata['property_type']
  end
  
  # Calculate area for polygon properties (in square meters)
  def area
    return nil unless location_type == 'polygon' && geometry.is_a?(Array)
    
    # Simple polygon area calculation using Shoelace formula
    # Note: This is approximate and works best for small areas
    points = geometry.map { |p| [p['latitude'].to_f, p['longitude'].to_f] }
    return nil if points.length < 3
    
    area = 0.0
    points.each_with_index do |point, i|
      j = (i + 1) % points.length
      area += point[0] * points[j][1]
      area -= points[j][0] * point[1]
    end
    
    # Convert to square meters (approximate)
    # 1 degree latitude ≈ 111,111 meters
    # 1 degree longitude varies by latitude
    avg_lat = points.sum { |p| p[0] } / points.length
    lat_to_meters = 111_111
    lon_to_meters = 111_111 * Math.cos(avg_lat * Math::PI / 180)
    
    (area.abs / 2 * lat_to_meters * lon_to_meters).round(2)
  end
  
  # Convert area to acres
  def area_in_acres
    return nil unless area
    (area / 4046.86).round(2)  # 1 acre = 4046.86 square meters
  end
  
  # Get the center point of the location
  def center_point
    case location_type
    when 'point'
      geometry
    when 'polygon'
      return nil unless geometry.is_a?(Array) && geometry.any?
      
      lat_sum = geometry.sum { |p| p['latitude'].to_f }
      lon_sum = geometry.sum { |p| p['longitude'].to_f }
      
      {
        'latitude' => lat_sum / geometry.length,
        'longitude' => lon_sum / geometry.length
      }
    end
  end
  
  # Create a property location from Google Maps data
  def self.create_from_geocode_result(result, location_type: 'point', property_type: nil)
    metadata = {
      formatted_address: result[:formatted_address],
      place_id: result[:place_id],
      address_components: result[:address_components]
    }
    metadata[:property_type] = property_type if property_type
    
    geometry = if location_type == 'point'
      { 'latitude' => result[:latitude], 'longitude' => result[:longitude] }
    else
      # For polygon, start with viewport corners as a simple rectangle
      # User can refine this in the frontend
      viewport = result[:viewport]
      if viewport
        [
          { 'latitude' => viewport['northeast']['lat'], 'longitude' => viewport['northeast']['lng'] },
          { 'latitude' => viewport['northeast']['lat'], 'longitude' => viewport['southwest']['lng'] },
          { 'latitude' => viewport['southwest']['lat'], 'longitude' => viewport['southwest']['lng'] },
          { 'latitude' => viewport['southwest']['lat'], 'longitude' => viewport['northeast']['lng'] }
        ]
      else
        []
      end
    end
    
    create!(
      name: result[:formatted_address] || "Property at #{result[:latitude]}, #{result[:longitude]}",
      location_type: location_type,
      geometry: geometry,
      notes: metadata.to_json,
      status: 'active'
    )
  end

  def archive!
    update!(archived_at: Time.current)
  end

  private

  def validate_geometry
    case location_type
    when "point"
      validate_point_geometry
    when "polygon"
      validate_polygon_geometry
    else
      errors.add(:geometry, "is not valid for the specified location_type")
    end
  end

  def validate_point_geometry
    unless geometry.is_a?(Hash) && geometry.key?("latitude") && geometry.key?("longitude")
      errors.add(:geometry, "must be a hash with 'latitude' and 'longitude' for a point")
      return
    end

    unless geometry["latitude"].is_a?(Numeric) && geometry["longitude"].is_a?(Numeric)
      errors.add(:geometry, "latitude and longitude must be numbers")
    end
  end

  def validate_polygon_geometry
    unless geometry.is_a?(Array) && geometry.all? { |point| point.is_a?(Hash) && point.key?("latitude") && point.key?("longitude") }
      errors.add(:geometry, "must be an array of hashes with 'latitude' and 'longitude' for a polygon")
      return
    end

    unless geometry.all? { |point| point["latitude"].is_a?(Numeric) && point["longitude"].is_a?(Numeric) }
        errors.add(:geometry, "all polygon points must have numeric latitude and longitude")
    end
  end
end
