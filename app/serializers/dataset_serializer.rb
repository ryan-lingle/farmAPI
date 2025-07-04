# app/serializers/dataset_serializer.rb
class DatasetSerializer
  include JSONAPI::Serializer
  set_type :dataset

  attributes :resolution, :description
end
