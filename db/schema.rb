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

ActiveRecord::Schema[8.1].define(version: 2026_11_17_074102) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "eras", force: :cascade do |t|
    t.string "name", null: false
    t.date "starts_on", null: false
    t.date "ends_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_eras_on_name", unique: true
    t.check_constraint "ends_on IS NULL OR starts_on < ends_on", name: "eras_starts_before_ends"
    t.exclusion_constraint "daterange(starts_on, ends_on, '[]'::text) WITH &&", using: :gist, name: "eras_no_overlap"
  end

  create_table "weight_classes", force: :cascade do |t|
    t.string "name", null: false
    t.integer "limit_lbs"
    t.integer "position", null: false
    t.boolean "spinnable", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_weight_classes_on_name", unique: true
    t.index ["position"], name: "index_weight_classes_on_position", unique: true
    t.check_constraint "limit_lbs IS NULL OR limit_lbs > 0", name: "weight_classes_limit_lbs_positive"
  end
end
