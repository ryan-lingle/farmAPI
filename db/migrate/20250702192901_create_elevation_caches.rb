class CreateElevationCaches < ActiveRecord::Migration[8.0]
  def change
    create_table :elevation_caches do |t|
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.float :elevation
      t.string :dataset, null: false

      t.timestamps
    end

    add_index :elevation_caches, [ :latitude, :longitude, :dataset ],
              name: 'index_elevation_cache_on_coords_and_dataset'
  end
end
