class AddRatingsRefreshedAtToIngestionRuns < ActiveRecord::Migration[8.1]
  def change
    # Set by Rails once ratings include this run's data. NULL on a succeeded run
    # means a refresh is still owed.
    add_column :ingestion_runs, :ratings_refreshed_at, :datetime
  end
end
