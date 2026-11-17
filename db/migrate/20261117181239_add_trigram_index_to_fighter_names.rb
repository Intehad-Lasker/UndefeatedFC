class AddTrigramIndexToFighterNames < ActiveRecord::Migration[8.1]
  def change
    # pg_trgm splits text into three-letter chunks, so "nurmagomedv" still finds
    # "Nurmagomedov" and ILIKE '%vance%' can use an index instead of a full scan.
    enable_extension "pg_trgm"
    add_index :fighters, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_fighters_on_name_trigram"
  end
end
