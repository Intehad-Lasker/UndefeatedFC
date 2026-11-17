require "test_helper"

class LeaderboardChannelTest < ActionCable::Channel::TestCase
  test "subscribes to the daily board" do
    subscribe board: "daily"

    assert subscription.confirmed?
    assert_has_stream "leaderboard:daily"
  end

  test "subscribes to the all-time board" do
    subscribe board: "all_time"

    assert_has_stream "leaderboard:all_time"
  end

  test "rejects unknown boards" do
    subscribe board: "secret"

    assert subscription.rejected?
  end
end
