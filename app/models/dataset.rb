# app/models/dataset.rb
class Dataset
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :id, :resolution, :description

  def initialize(attributes = {})
    super
    @id ||= attributes[:id]
  end

  def attributes
    {
      "id" => id,
      "resolution" => resolution,
      "description" => description
    }
  end
end
