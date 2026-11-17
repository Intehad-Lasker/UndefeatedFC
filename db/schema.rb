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

ActiveRecord::Schema[8.1].define(version: 2026_11_17_074251) do
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

  create_table "fighters", force: :cascade do |t|
    t.string "ufcstats_id", null: false
    t.string "name", null: false
    t.string "nickname"
    t.integer "height_cm"
    t.integer "reach_cm"
    t.string "stance"
    t.date "born_on"
    t.integer "wins", default: 0, null: false
    t.integer "losses", default: 0, null: false
    t.integer "draws", default: 0, null: false
    t.integer "no_contests", default: 0, null: false
    t.decimal "sig_strikes_landed_per_min", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "sig_strikes_absorbed_per_min", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "takedowns_per_15_min", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "submission_attempts_per_15_min", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "sig_strike_accuracy", precision: 4, scale: 3, default: "0.0", null: false
    t.decimal "sig_strike_defense", precision: 4, scale: 3, default: "0.0", null: false
    t.decimal "takedown_accuracy", precision: 4, scale: 3, default: "0.0", null: false
    t.decimal "takedown_defense", precision: 4, scale: 3, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ufcstats_id"], name: "index_fighters_on_ufcstats_id", unique: true
    t.check_constraint "draws >= 0", name: "fighters_draws_non_negative"
    t.check_constraint "losses >= 0", name: "fighters_losses_non_negative"
    t.check_constraint "no_contests >= 0", name: "fighters_no_contests_non_negative"
    t.check_constraint "sig_strike_accuracy >= 0::numeric AND sig_strike_accuracy <= 1::numeric", name: "fighters_sig_strike_accuracy_between_0_and_1"
    t.check_constraint "sig_strike_defense >= 0::numeric AND sig_strike_defense <= 1::numeric", name: "fighters_sig_strike_defense_between_0_and_1"
    t.check_constraint "sig_strikes_absorbed_per_min >= 0::numeric", name: "fighters_sig_strikes_absorbed_per_min_non_negative"
    t.check_constraint "sig_strikes_landed_per_min >= 0::numeric", name: "fighters_sig_strikes_landed_per_min_non_negative"
    t.check_constraint "submission_attempts_per_15_min >= 0::numeric", name: "fighters_submission_attempts_per_15_min_non_negative"
    t.check_constraint "takedown_accuracy >= 0::numeric AND takedown_accuracy <= 1::numeric", name: "fighters_takedown_accuracy_between_0_and_1"
    t.check_constraint "takedown_defense >= 0::numeric AND takedown_defense <= 1::numeric", name: "fighters_takedown_defense_between_0_and_1"
    t.check_constraint "takedowns_per_15_min >= 0::numeric", name: "fighters_takedowns_per_15_min_non_negative"
    t.check_constraint "wins >= 0", name: "fighters_wins_non_negative"
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
