class CreateDraftRounds < ActiveRecord::Migration[8.1]
  def change
    # A round is created by a spin (weight class + era) and completed by a pick
    # (fighter + slot). The indexes below enforce the game rules in the database.
    create_table :draft_rounds do |t|
      t.references :draft, type: :uuid, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :number, null: false
      t.references :weight_class, null: false, foreign_key: true
      t.references :era, null: false, foreign_key: true
      t.references :fighter, foreign_key: true, index: false
      t.string :slot
      t.integer :rating # the fighter's rating in the slot when picked, so later refreshes don't change results
      t.datetime :picked_at

      t.timestamps
    end

    add_index :draft_rounds, %i[draft_id number], unique: true
    # Each slot is filled once and each fighter is drafted once per draft.
    # NULLs are distinct in Postgres, so open rounds don't collide.
    add_index :draft_rounds, %i[draft_id slot], unique: true
    add_index :draft_rounds, %i[draft_id fighter_id], unique: true
    # At most one spun-but-unpicked round per draft.
    add_index :draft_rounds, :draft_id, unique: true, where: "fighter_id IS NULL",
      name: "index_draft_rounds_one_open_round_per_draft"

    add_check_constraint :draft_rounds, "number >= 1", name: "draft_rounds_number_positive"
    add_check_constraint :draft_rounds, "rating BETWEEN 0 AND 99", name: "draft_rounds_rating_range"
    add_check_constraint :draft_rounds,
      "(fighter_id IS NULL AND slot IS NULL AND rating IS NULL AND picked_at IS NULL) OR " \
      "(fighter_id IS NOT NULL AND slot IS NOT NULL AND rating IS NOT NULL AND picked_at IS NOT NULL)",
      name: "draft_rounds_pick_is_complete"
  end
end
