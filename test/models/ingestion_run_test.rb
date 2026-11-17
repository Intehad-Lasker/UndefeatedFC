require "test_helper"

class IngestionRunTest < ActiveSupport::TestCase
  test "starts as running from the ufcstats source" do
    run = IngestionRun.create!(started_at: Time.current)

    assert run.running?
    assert_equal "ufcstats", run.source
  end

  test "rejects an unknown status" do
    run = ingestion_runs(:succeeded)
    run.status = "paused"

    assert_not run.valid?
  end

  test "rejects a finish time before the start time" do
    run = ingestion_runs(:succeeded)
    run.finished_at = run.started_at - 1.minute

    assert_not run.valid?
    assert run.errors.key?(:finished_at)
  end

  test "database rejects a finish time before the start time" do
    run = ingestion_runs(:succeeded)

    assert_raises(ActiveRecord::StatementInvalid) do
      run.update_column(:finished_at, run.started_at - 1.minute)
    end
  end

  test "duration is the time between start and finish" do
    assert_equal 750, ingestion_runs(:succeeded).duration
    assert_nil IngestionRun.new(started_at: Time.current).duration
  end

  test "recent_first lists the newest run first" do
    assert_equal ingestion_runs(:failed, :succeeded), IngestionRun.recent_first.to_a
  end

  test "awaiting_ratings lists succeeded runs whose data is not rated yet" do
    assert_equal [ ingestion_runs(:succeeded) ], IngestionRun.awaiting_ratings.to_a

    ingestion_runs(:succeeded).update!(ratings_refreshed_at: Time.current)

    assert_empty IngestionRun.awaiting_ratings
  end
end
