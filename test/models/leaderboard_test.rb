require "test_helper"

class LeaderboardTest < ActiveSupport::TestCase
  def finish(user:, wins:, overall:, challenge: nil, at: Time.utc(2026, 11, 17, 12))
    Draft.create!(user: user, daily_challenge: challenge, status: :completed, wins: wins, losses: 15 - wins,
                  overall: overall, completed_at: at, seed: SecureRandom.random_number(Draft::SEED_RANGE))
  end

  def third_player = @third ||= User.create!(email_address: "three@example.com", display_name: "ThirdPlayer", password: "long enough password")

  setup { @challenge = daily_challenges(:yesterday) }

  test "daily ranks the day's finished attempts by wins, then overall" do
    finish(user: users(:one), wins: 12, overall: 80, challenge: @challenge)
    finish(user: users(:two), wins: 14, overall: 85, challenge: @challenge)
    finish(user: third_player, wins: 12, overall: 88, challenge: @challenge)

    entries = Leaderboard.daily(@challenge).entries

    assert_equal %w[SecondPlayer ThirdPlayer FirstPlayer], entries.map(&:display_name)
    assert_equal [ 1, 2, 3 ], entries.map(&:rank)
    assert_equal "14-1", entries.first.record
  end

  test "identical results share a rank, and the earlier finisher is listed first" do
    finish(user: users(:one), wins: 13, overall: 84, challenge: @challenge, at: Time.utc(2026, 11, 17, 15))
    finish(user: users(:two), wins: 13, overall: 84, challenge: @challenge, at: Time.utc(2026, 11, 17, 9))

    entries = Leaderboard.daily(@challenge).entries

    assert_equal [ 1, 1 ], entries.map(&:rank)
    assert_equal %w[SecondPlayer FirstPlayer], entries.map(&:display_name)
  end

  test "daily leaves out other days, unfinished drafts and guests" do
    finish(user: users(:one), wins: 10, overall: 70, challenge: @challenge)
    finish(user: users(:two), wins: 15, overall: 95)
    finish(user: nil, wins: 15, overall: 99, challenge: @challenge)
    Draft.create!(user: third_player, daily_challenge: @challenge)

    assert_equal %w[FirstPlayer], Leaderboard.daily(@challenge).entries.map(&:display_name)
  end

  test "all-time shows each player's best run once" do
    finish(user: users(:one), wins: 9, overall: 60)
    finish(user: users(:one), wins: 15, overall: 92)
    finish(user: users(:two), wins: 13, overall: 86)

    entries = Leaderboard.all_time.entries

    assert_equal [ [ "FirstPlayer", "15-0" ], [ "SecondPlayer", "13-2" ] ], entries.map { |e| [ e.display_name, e.record ] }
    assert entries.first.undefeated?
  end

  test "respects the limit" do
    finish(user: users(:one), wins: 9, overall: 60)
    finish(user: users(:two), wins: 13, overall: 86)

    assert_equal 1, Leaderboard.all_time(limit: 1).entries.size
  end

  test "version changes when a draft on the board finishes" do
    board = Leaderboard.daily(@challenge)
    before = board.version
    finish(user: users(:one), wins: 10, overall: 70, challenge: @challenge)

    assert_not_equal before, board.version
  end
end
