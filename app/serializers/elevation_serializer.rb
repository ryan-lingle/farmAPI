# app/serializers/elevation_serializer.rb
class ElevationSerializer
  include JSONAPI::Serializer
  set_type :elevation

  attributes :latitude, :longitude, :elevation, :dataset, :cached, :simulated, :units

  attribute :error, if: proc { |record| record.error.present? }
end
