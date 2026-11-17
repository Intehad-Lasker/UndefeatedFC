require "test_helper"

class CreateDailyChallengeJobTest < ActiveJob::TestCase
  test "creates today's and tomorrow's challenges" do
    assert_difference -> { DailyChallenge.count }, 2 do
      CreateDailyChallengeJob.perform_now(Date.new(2026, 12, 24))
    end

    assert_equal [ Date.new(2026, 12, 24), Date.new(2026, 12, 25) ], DailyChallenge.order(:day).last(2).map(&:day)
  end

  test "running again changes nothing" do
    CreateDailyChallengeJob.perform_now(Date.new(2026, 12, 24))

    assert_no_difference -> { DailyChallenge.count } do
      CreateDailyChallengeJob.perform_now(Date.new(2026, 12, 24))
    end
  end

  test "is scheduled nightly in production" do
    task = YAML.load_file(Rails.root.join("config/recurring.yml")).dig("production", "create_daily_challenge")

    assert_equal "CreateDailyChallengeJob", task["class"]
    assert_equal "every day at 23:50", task["schedule"]
  end
end
