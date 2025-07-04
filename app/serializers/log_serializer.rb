class LogSerializer
  include JSONAPI::Serializer

  set_type :log

  attributes :name, :status, :notes, :timestamp, :log_type, :created_at, :updated_at

  has_many :quantities
  has_many :assets
end
