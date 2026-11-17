class AddPlayerIdToDrafts < ActiveRecord::Migration[8.1]
  def change
    # The anonymous browser that started the draft; only it may spin or pick.
    add_column :drafts, :player_id, :uuid
    add_index :drafts, :player_id
  end
end
