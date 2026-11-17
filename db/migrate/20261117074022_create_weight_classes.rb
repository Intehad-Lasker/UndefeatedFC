class CreateWeightClasses < ActiveRecord::Migration[8.1]
  def change
    create_table :weight_classes do |t|
      t.string :name, null: false
      t.integer :limit_lbs
      t.integer :position, null: false
      t.boolean :spinnable, null: false, default: true

      t.timestamps
    end

    add_index :weight_classes, :name, unique: true
    add_index :weight_classes, :position, unique: true
    add_check_constraint :weight_classes, "limit_lbs IS NULL OR limit_lbs > 0",
      name: "weight_classes_limit_lbs_positive"
  end
end
