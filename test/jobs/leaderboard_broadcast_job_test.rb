require "test_helper"

class LeaderboardBroadcastJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  def finished(user:, challenge: nil)
    Draft.create!(user: user, daily_challenge: challenge, status: :completed, wins: 12, losses: 3, overall: 80,
                  completed_at: Time.current)
  end

  test "a finished challenge attempt updates both boards" do
    draft = finished(user: users(:one), challenge: daily_challenges(:yesterday))

    assert_broadcast_on("leaderboard:daily", { board: "daily", day: Date.new(2026, 11, 16) }) do
      assert_broadcasts("leaderboard:all_time", 1) { LeaderboardBroadcastJob.perform_now(draft.id) }
    end
  end

  test "a finished ordinary draft only updates the all-time board" do
    draft = finished(user: users(:one))

    assert_no_broadcasts("leaderboard:daily") do
      assert_broadcasts("leaderboard:all_time", 1) { LeaderboardBroadcastJob.perform_now(draft.id) }
    end
  end

  test "guest drafts are not announced" do
    draft = finished(user: nil)

    assert_no_broadcasts("leaderboard:all_time") { LeaderboardBroadcastJob.perform_now(draft.id) }
  end
end
