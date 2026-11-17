class CreateDrafts < ActiveRecord::Migration[8.1]
  def change
    # UUID primary key: the id appears in share links, so it must not be guessable
    # or reveal how many drafts exist.
    create_table :drafts, id: :uuid do |t|
      t.bigint :seed, null: false
      t.string :status, null: false, default: "in_progress"
      t.integer :overall
      t.integer :wins
      t.integer :losses
      t.jsonb :fight_log, null: false, default: []
      t.datetime :completed_at

      t.timestamps
    end

    add_index :drafts, %i[status overall]
    add_check_constraint :drafts, "status IN ('in_progress', 'completed')", name: "drafts_status_known"
    add_check_constraint :drafts, "overall BETWEEN 0 AND 99", name: "drafts_overall_range"
    add_check_constraint :drafts, "wins >= 0 AND losses >= 0", name: "drafts_record_non_negative"
    add_check_constraint :drafts,
      "status <> 'completed' OR (overall IS NOT NULL AND wins IS NOT NULL AND losses IS NOT NULL AND completed_at IS NOT NULL)",
      name: "drafts_completed_has_result"
  end
end
