Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # API routes
  namespace :api do
    namespace :v1 do
      # Root API endpoint
      root to: "base#index"
      get "schema", to: "base#schema"

      # Asset routes
      scope "assets" do
        get ":asset_type", to: "assets#index"
        post ":asset_type", to: "assets#create"
        get ":asset_type/:id", to: "assets#show"
        patch ":asset_type/:id", to: "assets#update"
        delete ":asset_type/:id", to: "assets#destroy"
      end

      # Log routes
      scope "logs" do
        get ":log_type", to: "logs#index"
        post ":log_type", to: "logs#create"
        get ":log_type/:id", to: "logs#show"
        patch ":log_type/:id", to: "logs#update"
        delete ":log_type/:id", to: "logs#destroy"
      end

      # Taxonomy term routes
      scope "taxonomy_terms" do
        get ":vocabulary", to: "taxonomy_terms#index"
        post ":vocabulary", to: "taxonomy_terms#create"
        get ":vocabulary/:id", to: "taxonomy_terms#show"
        patch ":vocabulary/:id", to: "taxonomy_terms#update"
        delete ":vocabulary/:id", to: "taxonomy_terms#destroy"
      end

      # Quantity routes
      resources :quantities, only: [ :index, :show, :create, :update, :destroy ]

      # Location routes
      resources :locations, only: [ :index, :show, :create, :update, :destroy ]

      # Elevation API routes
      scope "elevation" do
        get "point", to: "elevation#point"
        post "profile", to: "elevation#profile"
        get "datasets", to: "elevation#datasets"
        get "usgs_dem", to: "elevation#usgs_dem"
        get "catalog", to: "elevation#catalog"
      end
      
      # Geocoding API routes
      scope "geocoding" do
        get "geocode", to: "geocoding#geocode"
        get "reverse", to: "geocoding#reverse_geocode"
        get "search_nearby", to: "geocoding#search_nearby"
        get "place/:place_id", to: "geocoding#place_details"
      end
      
      # Properties API routes
      scope "properties" do
        get "/", to: "properties#index"
        get "/:id", to: "properties#show"
        post "create_from_address", to: "properties#create_from_address"
        patch "/:id/boundaries", to: "properties#update_boundaries"
        get "search/nearby", to: "properties#search_nearby"
        post "/:id/link_asset", to: "properties#link_to_asset"
      end
    end
  end

  # Redirect root to API
  root to: redirect("/api/v1")

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
