# app/serializers/location_serializer.rb
class LocationSerializer
  include JSONAPI::Serializer

  attributes :name, :status, :notes, :location_type, :geometry, :archived_at, :created_at, :updated_at
  
  # Include computed attributes
  attribute :metadata do |location|
    location.metadata
  end
  
  attribute :center_point do |location|
    location.center_point
  end
  
  attribute :area_in_acres do |location|
    location.area_in_acres
  end
  
  attribute :property_type do |location|
    location.property_type
  end
  
  attribute :address do |location|
    location.address
  end
end
