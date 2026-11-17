class CreateDailyChallenges < ActiveRecord::Migration[8.1]
  def change
    # One shared seed per UTC day: every player's challenge draft spins the
    # same pools in the same order.
    create_table :daily_challenges do |t|
      t.date :day, null: false
      t.bigint :seed, null: false

      t.timestamps
    end

    add_index :daily_challenges, :day, unique: true
  end
end
