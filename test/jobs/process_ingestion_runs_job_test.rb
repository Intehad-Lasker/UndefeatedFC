require "test_helper"

class ProcessIngestionRunsJobTest < ActiveJob::TestCase
  test "refreshes ratings and marks a newly succeeded run as processed" do
    FighterRating.delete_all

    ProcessIngestionRunsJob.perform_now

    assert_equal Fighter.count * Skills.all.size, FighterRating.count
    assert_not_nil ingestion_runs(:succeeded).reload.ratings_refreshed_at
  end

  test "does nothing when no run is waiting" do
    ingestion_runs(:succeeded).update!(ratings_refreshed_at: 1.hour.ago)
    FighterRating.delete_all

    ProcessIngestionRunsJob.perform_now

    assert_equal 0, FighterRating.count
  end

  test "ignores failed and running runs" do
    ingestion_runs(:succeeded).update!(ratings_refreshed_at: 1.hour.ago)
    IngestionRun.create!(started_at: Time.current)

    ProcessIngestionRunsJob.perform_now

    assert_nil ingestion_runs(:failed).reload.ratings_refreshed_at
    assert_equal 1, IngestionRun.running.where(ratings_refreshed_at: nil).count
  end

  test "is scheduled in production" do
    tasks = YAML.load_file(Rails.root.join("config/recurring.yml")).fetch("production")

    assert_equal "ProcessIngestionRunsJob", tasks.dig("process_ingestion_runs", "class")
  end
end
