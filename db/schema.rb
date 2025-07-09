# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_09_134907) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assets", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.text "notes"
    t.boolean "is_location"
    t.boolean "is_fixed"
    t.string "asset_type"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "assets_logs", id: false, force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.bigint "log_id", null: false
    t.index ["asset_id"], name: "index_assets_logs_on_asset_id"
    t.index ["log_id"], name: "index_assets_logs_on_log_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.text "notes"
    t.string "location_type"
    t.jsonb "geometry"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "logs", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.text "notes"
    t.string "log_type"
    t.datetime "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "quantities", force: :cascade do |t|
    t.string "label"
    t.string "measure"
    t.decimal "value"
    t.string "quantity_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unit"
    t.bigint "log_id"
    t.index ["log_id"], name: "index_quantities_on_log_id"
  end

  create_table "taxonomy_terms", force: :cascade do |t|
    t.string "name"
    t.string "vocabulary"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "quantities", "logs"
end
