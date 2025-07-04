class ElevationCache < ApplicationRecord
  validates :latitude, presence: true, numericality: true
  validates :longitude, presence: true, numericality: true
  validates :dataset, presence: true
  
  scope :for_location, ->(lat, lon, dataset) {
    where(latitude: lat, longitude: lon, dataset: dataset)
  }
  
  scope :recent, -> { where("created_at > ?", 7.days.ago) }
  
  def self.get_or_create(lat, lon, dataset = 'SRTMGL3')
    cached = for_location(lat, lon, dataset).recent.first
    return cached if cached
    
    # Get from OpenTopography service
    result = OpentopographyService.get_elevation(lat, lon, dataset)
    
    if result[:success]
      create!(
        latitude: lat,
        longitude: lon,
        elevation: result[:elevation],
        dataset: dataset
      )
    else
      nil
    end
  end
end 