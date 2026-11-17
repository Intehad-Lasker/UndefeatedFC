class AddUserToDrafts < ActiveRecord::Migration[8.1]
  def change
    # NULL for guests. Guest drafts are claimed when that browser signs in.
    add_reference :drafts, :user, foreign_key: { on_delete: :nullify }, index: false
    add_index :drafts, %i[user_id created_at]
  end
end
