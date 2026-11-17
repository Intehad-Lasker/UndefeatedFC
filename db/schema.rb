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

ActiveRecord::Schema[8.1].define(version: 2026_11_17_074534) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "appearances", force: :cascade do |t|
    t.bigint "bout_id", null: false
    t.bigint "fighter_id", null: false
    t.string "outcome", null: false
    t.integer "knockdowns", default: 0, null: false
    t.integer "sig_strikes_landed", default: 0, null: false
    t.integer "takedowns_landed", default: 0, null: false
    t.integer "submission_attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bout_id", "fighter_id"], name: "index_appearances_on_bout_id_and_fighter_id", unique: true
    t.index ["bout_id"], name: "index_appearances_on_bout_id"
    t.index ["fighter_id"], name: "index_appearances_on_fighter_id"
    t.check_constraint "knockdowns >= 0", name: "appearances_knockdowns_non_negative"
    t.check_constraint "outcome::text = ANY (ARRAY['win'::character varying, 'loss'::character varying, 'draw'::character varying, 'no_contest'::character varying]::text[])", name: "appearances_outcome_known"
    t.check_constraint "sig_strikes_landed >= 0", name: "appearances_sig_strikes_landed_non_negative"
    t.check_constraint "submission_attempts >= 0", name: "appearances_submission_attempts_non_negative"
    t.check_constraint "takedowns_landed >= 0", name: "appearances_takedowns_landed_non_negative"
  end

  create_table "bouts", force: :cascade do |t|
    t.string "ufcstats_id", null: false
    t.bigint "event_id", null: false
    t.bigint "weight_class_id", null: false
    t.string "finish", null: false
    t.string "finish_detail"
    t.integer "ending_round"
    t.integer "ending_time_seconds"
    t.boolean "title_bout", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_bouts_on_event_id"
    t.index ["ufcstats_id"], name: "index_bouts_on_ufcstats_id", unique: true
    t.index ["weight_class_id"], name: "index_bouts_on_weight_class_id"
    t.check_constraint "ending_round >= 1 AND ending_round <= 5", name: "bouts_ending_round_range"
    t.check_constraint "ending_time_seconds >= 0 AND ending_time_seconds <= 300", name: "bouts_ending_time_range"
    t.check_constraint "finish::text = ANY (ARRAY['ko_tko'::character varying, 'submission'::character varying, 'decision'::character varying, 'disqualification'::character varying, 'no_contest'::character varying, 'other'::character varying]::text[])", name: "bouts_finish_known"
  end

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

  create_table "events", force: :cascade do |t|
    t.string "ufcstats_id", null: false
    t.string "name", null: false
    t.date "held_on", null: false
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["held_on"], name: "index_events_on_held_on"
    t.index ["ufcstats_id"], name: "index_events_on_ufcstats_id", unique: true
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

  create_table "ingestion_runs", force: :cascade do |t|
    t.string "source", default: "ufcstats", null: false
    t.string "status", default: "running", null: false
    t.datetime "started_at", null: false
    t.datetime "finished_at"
    t.integer "events_count", default: 0, null: false
    t.integer "bouts_count", default: 0, null: false
    t.integer "fighters_count", default: 0, null: false
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status", "finished_at"], name: "index_ingestion_runs_on_status_and_finished_at"
    t.check_constraint "finished_at IS NULL OR finished_at >= started_at", name: "ingestion_runs_finishes_after_start"
    t.check_constraint "status::text = ANY (ARRAY['running'::character varying, 'succeeded'::character varying, 'failed'::character varying]::text[])", name: "ingestion_runs_status_known"
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

  add_foreign_key "appearances", "bouts"
  add_foreign_key "appearances", "fighters"
  add_foreign_key "bouts", "events"
  add_foreign_key "bouts", "weight_classes"
end
