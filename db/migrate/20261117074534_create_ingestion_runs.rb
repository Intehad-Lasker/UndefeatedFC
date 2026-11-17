class CreateIngestionRuns < ActiveRecord::Migration[8.1]
  def change
    # Written by the Python scraper; read by Rails to know when new data landed.
    create_table :ingestion_runs do |t|
      t.string :source, null: false, default: "ufcstats"
      t.string :status, null: false, default: "running"
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.integer :events_count, null: false, default: 0
      t.integer :bouts_count, null: false, default: 0
      t.integer :fighters_count, null: false, default: 0
      t.text :error_message

      t.timestamps
    end

    add_index :ingestion_runs, %i[status finished_at]
    add_check_constraint :ingestion_runs, "status IN ('running', 'succeeded', 'failed')",
      name: "ingestion_runs_status_known"
    add_check_constraint :ingestion_runs, "finished_at IS NULL OR finished_at >= started_at",
      name: "ingestion_runs_finishes_after_start"
  end
end
