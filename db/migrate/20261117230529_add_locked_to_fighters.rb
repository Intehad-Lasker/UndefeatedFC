class AddLockedToFighters < ActiveRecord::Migration[8.1]
  def change
    # Set when an admin corrects a fighter; the scraper leaves locked rows alone.
    add_column :fighters, :locked, :boolean, null: false, default: false
  end
end
