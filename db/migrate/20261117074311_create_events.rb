class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :ufcstats_id, null: false
      t.string :name, null: false
      t.date :held_on, null: false
      t.string :location

      t.timestamps
    end

    add_index :events, :ufcstats_id, unique: true
    add_index :events, :held_on
  end
end
