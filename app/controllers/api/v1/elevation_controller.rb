module Api
  module V1
    class ElevationController < BaseController
      def point
        lat = params[:latitude]&.to_f
        lon = params[:longitude]&.to_f
        dataset = params[:dataset] || 'SRTMGL3'

        if lat.nil? || lon.nil?
          render json: { error: "Latitude and longitude are required" }, status: :bad_request
          return
        end

        # Check cache first
        cached = ElevationCache.for_location(lat, lon, dataset).recent.first
        
        if cached
          render json: {
            latitude: lat,
            longitude: lon,
            elevation: cached.elevation,
            dataset: dataset,
            cached: true
          }
          return
        end

        # Get from OpenTopography service
        result = OpentopographyService.get_elevation(lat, lon, dataset)
        
        if result[:success]
          # Cache the result
          ElevationCache.create!(
            latitude: lat,
            longitude: lon,
            elevation: result[:elevation],
            dataset: dataset
          )

          render json: {
            latitude: lat,
            longitude: lon,
            elevation: result[:elevation],
            dataset: dataset,
            cached: false
          }
        else
          # Return simulated elevation on error
          simulated_elevation = simulate_elevation(lat, lon)
          
          render json: {
            latitude: lat,
            longitude: lon,
            elevation: simulated_elevation,
            dataset: dataset,
            simulated: true,
            error: result[:error]
          }
        end
      end

      def profile
        points = params[:points]
        dataset = params[:dataset] || 'SRTMGL3'

        if points.nil? || !points.is_a?(Array)
          render json: { error: "Points array is required" }, status: :bad_request
          return
        end

        elevations = points.map do |point|
          lat = point[:latitude]&.to_f
          lon = point[:longitude]&.to_f
          
          next { error: "Invalid point" } if lat.nil? || lon.nil?

          # Check cache
          cached = ElevationCache.for_location(lat, lon, dataset).recent.first
          
          if cached
            { latitude: lat, longitude: lon, elevation: cached.elevation }
          else
            # Get from service
            result = OpentopographyService.get_elevation(lat, lon, dataset)
            
            if result[:success]
              ElevationCache.create!(
                latitude: lat,
                longitude: lon,
                elevation: result[:elevation],
                dataset: dataset
              )
              { latitude: lat, longitude: lon, elevation: result[:elevation] }
            else
              { latitude: lat, longitude: lon, elevation: simulate_elevation(lat, lon) }
            end
          end
        end

        render json: { elevations: elevations }
      end

      def datasets
        datasets = OpentopographyService.available_datasets
        render json: { datasets: datasets }
      end

      def usgs_dem
        # Placeholder for USGS DEM endpoint
        render json: { message: "USGS DEM endpoint not yet implemented" }
      end

      def catalog
        # Placeholder for catalog endpoint
        render json: { message: "Catalog endpoint not yet implemented" }
      end

      private

      def simulate_elevation(lat, lon)
        # Simple elevation simulation based on coordinates
        base = 200.0
        variation = Math.sin(lat * Math::PI / 180) * 50 + Math.cos(lon * Math::PI / 180) * 30
        (base + variation + rand(-10.0..10.0)).round(2)
      end
    end
  end
end 