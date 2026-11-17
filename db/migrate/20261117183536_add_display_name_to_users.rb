class AddDisplayNameToUsers < ActiveRecord::Migration[8.1]
  # The public name on leaderboards, unique regardless of case so "Khabib" and
  # "khabib" can't both exist. Existing users get a placeholder before the
  # column becomes NOT NULL, so the migration works on a database with users.
  def up
    add_column :users, :display_name, :string
    execute "UPDATE users SET display_name = 'player_' || id WHERE display_name IS NULL"
    change_column_null :users, :display_name, false
    add_index :users, "lower(display_name)", unique: true, name: "index_users_on_lower_display_name"
  end

  def down
    remove_index :users, name: "index_users_on_lower_display_name"
    remove_column :users, :display_name
  end
end
