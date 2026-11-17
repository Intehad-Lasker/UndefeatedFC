class CreateFighters < ActiveRecord::Migration[8.1]
  PERCENT_COLUMNS = %i[sig_strike_accuracy sig_strike_defense takedown_accuracy takedown_defense].freeze
  RATE_COLUMNS = %i[sig_strikes_landed_per_min sig_strikes_absorbed_per_min
                    takedowns_per_15_min submission_attempts_per_15_min].freeze
  RECORD_COLUMNS = %i[wins losses draws no_contests].freeze

  def change
    create_table :fighters do |t|
      t.string :ufcstats_id, null: false
      t.string :name, null: false
      t.string :nickname
      t.integer :height_cm
      t.integer :reach_cm
      t.string :stance
      t.date :born_on

      # Professional record as listed on UFCStats (includes non-UFC fights).
      RECORD_COLUMNS.each { |column| t.integer column, null: false, default: 0 }

      # Career averages from UFCStats. Percentages are stored as 0..1.
      RATE_COLUMNS.each { |column| t.decimal column, precision: 5, scale: 2, null: false, default: 0 }
      PERCENT_COLUMNS.each { |column| t.decimal column, precision: 4, scale: 3, null: false, default: 0 }

      t.timestamps
    end

    add_index :fighters, :ufcstats_id, unique: true

    RECORD_COLUMNS.each do |column|
      add_check_constraint :fighters, "#{column} >= 0", name: "fighters_#{column}_non_negative"
    end
    RATE_COLUMNS.each do |column|
      add_check_constraint :fighters, "#{column} >= 0", name: "fighters_#{column}_non_negative"
    end
    PERCENT_COLUMNS.each do |column|
      add_check_constraint :fighters, "#{column} BETWEEN 0 AND 1", name: "fighters_#{column}_between_0_and_1"
    end
  end
end
