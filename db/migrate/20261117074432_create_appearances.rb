class CreateAppearances < ActiveRecord::Migration[8.1]
  COUNT_COLUMNS = %i[knockdowns sig_strikes_landed takedowns_landed submission_attempts].freeze

  def change
    create_table :appearances do |t|
      t.references :bout, null: false, foreign_key: true
      t.references :fighter, null: false, foreign_key: true
      t.string :outcome, null: false
      COUNT_COLUMNS.each { |column| t.integer column, null: false, default: 0 }

      t.timestamps
    end

    add_index :appearances, %i[bout_id fighter_id], unique: true
    add_check_constraint :appearances, "outcome IN ('win', 'loss', 'draw', 'no_contest')",
      name: "appearances_outcome_known"
    COUNT_COLUMNS.each do |column|
      add_check_constraint :appearances, "#{column} >= 0", name: "appearances_#{column}_non_negative"
    end
  end
end
