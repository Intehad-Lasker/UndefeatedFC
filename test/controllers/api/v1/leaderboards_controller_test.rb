require "test_helper"

class Api::V1::LeaderboardsControllerTest < ActionDispatch::IntegrationTest
  def finish(user:, wins:, overall:, challenge: nil)
    Draft.create!(user: user, daily_challenge: challenge, status: :completed, wins: wins, losses: 15 - wins,
                  overall: overall, completed_at: Time.current, seed: SecureRandom.random_number(Draft::SEED_RANGE))
  end

  def with_memory_cache
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original
  end

  test "the daily board ranks a given day's attempts" do
    challenge = daily_challenges(:yesterday)
    finish(user: users(:one), wins: 11, overall: 79, challenge: challenge)
    finish(user: users(:two), wins: 15, overall: 93, challenge: challenge)

    get "/api/v1/leaderboards/daily", params: { day: "2026-11-16" }

    assert_response :ok
    body = response.parsed_body
    assert_equal "2026-11-16", body["day"]
    assert_equal [ [ 1, "SecondPlayer", "15-0", true ], [ 2, "FirstPlayer", "11-4", false ] ],
      body["entries"].map { |e| e.values_at("rank", "display_name", "record", "undefeated") }
  end

  test "the daily board defaults to today" do
    travel_to Time.utc(2026, 12, 9, 8) do
      get "/api/v1/leaderboards/daily"
    end

    assert_equal({ "day" => "2026-12-09", "entries" => [] }, response.parsed_body)
  end

  test "the all-time board lists each player's best run" do
    finish(user: users(:one), wins: 8, overall: 55)
    finish(user: users(:one), wins: 14, overall: 90)

    get "/api/v1/leaderboards/all_time"

    assert_equal [ "14-1" ], response.parsed_body["entries"].pluck("record")
  end

  test "an unchanged board answers 304 and is publicly cacheable" do
    get "/api/v1/leaderboards/all_time"
    assert_includes response.headers["Cache-Control"], "public"

    get "/api/v1/leaderboards/all_time", headers: { "If-None-Match" => response.headers["ETag"] }

    assert_response :not_modified
  end

  test "the ranking query runs once per change, then comes from the cache" do
    with_memory_cache do
      finish(user: users(:one), wins: 10, overall: 70)
      get "/api/v1/leaderboards/all_time"

      ranking_queries = 0
      counter = ->(*, payload) { ranking_queries += 1 if payload[:sql].include?("RANK()") }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { get "/api/v1/leaderboards/all_time" }
      assert_equal 0, ranking_queries

      travel 1.second do
        finish(user: users(:two), wins: 12, overall: 80)
        ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { get "/api/v1/leaderboards/all_time" }
      end
      assert_equal 1, ranking_queries
      assert_equal %w[SecondPlayer FirstPlayer], response.parsed_body["entries"].pluck("display_name")
    end
  end

  test "an unknown day is a 404 and a malformed one a 400" do
    get "/api/v1/leaderboards/daily", params: { day: "2020-01-01" }
    assert_response :not_found

    get "/api/v1/leaderboards/daily", params: { day: "yesterday" }
    assert_response :bad_request
  end
end
