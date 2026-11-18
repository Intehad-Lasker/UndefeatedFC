class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    # Two players, six shared rounds, alternating picks in snake order.
    create_table :matches, id: :uuid do |t|
      t.bigint :seed, null: false
      t.string :status, null: false, default: "waiting"
      t.jsonb :pools, null: false, default: [] # [[weight_class_id, era_id], ...] chosen at creation
      t.integer :winner_seat
      t.jsonb :result, null: false, default: {}
      t.datetime :completed_at

      t.timestamps
    end
    add_check_constraint :matches, "status IN ('waiting', 'drafting', 'completed')", name: "matches_status_known"
    add_check_constraint :matches, "winner_seat IN (1, 2)", name: "matches_winner_seat"

    create_table :match_players do |t|
      t.references :match, type: :uuid, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :seat, null: false
      t.uuid :player_id, null: false
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :display_name, null: false

      t.timestamps
    end
    add_index :match_players, %i[match_id seat], unique: true
    add_index :match_players, %i[match_id player_id], unique: true
    add_check_constraint :match_players, "seat IN (1, 2)", name: "match_players_seat"

    create_table :match_picks do |t|
      t.references :match, type: :uuid, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :number, null: false
      t.integer :seat, null: false
      t.references :fighter, null: false, foreign_key: true, index: false
      t.string :slot, null: false
      t.integer :rating, null: false

      t.timestamps
    end
    # Each turn is taken once, each fighter drafted once per match, and each
    # player fills each slot once.
    add_index :match_picks, %i[match_id number], unique: true
    add_index :match_picks, %i[match_id fighter_id], unique: true
    add_index :match_picks, %i[match_id seat slot], unique: true
    add_check_constraint :match_picks, "number BETWEEN 1 AND 12", name: "match_picks_number_range"
    add_check_constraint :match_picks, "seat IN (1, 2)", name: "match_picks_seat"
    add_check_constraint :match_picks, "rating BETWEEN 0 AND 99", name: "match_picks_rating_range"
  end
end
