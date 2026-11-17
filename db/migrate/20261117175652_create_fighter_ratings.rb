class CreateFighterRatings < ActiveRecord::Migration[8.1]
  def change
    # One row per fighter per skill. Rows rather than a column per skill, so a
    # new skill needs no migration.
    create_table :fighter_ratings do |t|
      t.references :fighter, null: false, foreign_key: true, index: false
      t.string :skill, null: false
      t.integer :value, null: false

      t.timestamps
    end

    add_index :fighter_ratings, %i[fighter_id skill], unique: true
    add_index :fighter_ratings, %i[skill value]
    add_check_constraint :fighter_ratings, "value BETWEEN 0 AND 99", name: "fighter_ratings_value_range"
  end
end
