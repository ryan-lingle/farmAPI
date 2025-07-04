# app/models/elevation.rb
class Elevation
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :id, :latitude, :longitude, :elevation, :dataset, :cached, :simulated, :units, :error

  def initialize(attributes = {})
    super
    @id ||= Digest::MD5.hexdigest("#{latitude}-#{longitude}-#{dataset}")
    @units ||= "meters"
  end

  def attributes
    {
      "id" => id,
      "latitude" => latitude,
      "longitude" => longitude,
      "elevation" => elevation,
      "dataset" => dataset,
      "cached" => cached,
      "simulated" => simulated,
      "units" => units,
      "error" => error
    }
  end
end
