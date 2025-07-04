# Ensure services are loaded
Rails.application.config.to_prepare do
  # Load elevation services
  require_relative "../../app/services/opentopography_service"
  require_relative "../../app/services/geotiff_processor"
end
