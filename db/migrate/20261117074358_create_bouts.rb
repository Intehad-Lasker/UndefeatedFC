class CreateBouts < ActiveRecord::Migration[8.1]
  FINISHES = %w[ko_tko submission decision disqualification no_contest other].freeze

  def change
    create_table :bouts do |t|
      t.string :ufcstats_id, null: false
      t.references :event, null: false, foreign_key: true
      t.references :weight_class, null: false, foreign_key: true
      t.string :finish, null: false
      t.string :finish_detail # raw method text from UFCStats, e.g. "S-DEC"
      t.integer :ending_round
      t.integer :ending_time_seconds
      t.boolean :title_bout, null: false, default: false

      t.timestamps
    end

    add_index :bouts, :ufcstats_id, unique: true
    add_check_constraint :bouts, "finish IN (#{FINISHES.map { |f| "'#{f}'" }.join(', ')})",
      name: "bouts_finish_known"
    add_check_constraint :bouts, "ending_round BETWEEN 1 AND 5", name: "bouts_ending_round_range"
    add_check_constraint :bouts, "ending_time_seconds BETWEEN 0 AND 300", name: "bouts_ending_time_range"
  end
end
