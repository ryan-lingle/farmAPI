class AssetSerializer
  include JSONAPI::Serializer

  set_type "asset"

  attributes :name, :status, :notes, :is_location, :is_fixed, :created_at, :updated_at, :archived_at

  attribute :asset_type do |object|
    object.asset_type || object.class.name.underscore.gsub("_asset", "")
  end

  link :self do |object|
    "/api/v1/assets/#{object.asset_type || object.class.name.underscore.gsub('_asset', '')}/#{object.id}"
  end
end
