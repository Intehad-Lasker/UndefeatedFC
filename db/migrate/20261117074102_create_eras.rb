class CreateEras < ActiveRecord::Migration[8.1]
  def change
    create_table :eras do |t|
      t.string :name, null: false
      t.date :starts_on, null: false
      t.date :ends_on # NULL means the era is still running

      t.timestamps
    end

    add_index :eras, :name, unique: true
    add_check_constraint :eras, "ends_on IS NULL OR starts_on < ends_on", name: "eras_starts_before_ends"
    # Two eras can never cover the same day.
    add_exclusion_constraint :eras, "daterange(starts_on, ends_on, '[]') WITH &&",
      using: :gist, name: "eras_no_overlap"
  end
end
