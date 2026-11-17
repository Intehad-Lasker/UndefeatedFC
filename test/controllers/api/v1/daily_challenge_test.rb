require "test_helper"

class Api::V1::DailyChallengeTest < ActionDispatch::IntegrationTest
  test "shows today's challenge with no attempt yet" do
    travel_to Time.utc(2026, 12, 5, 12) do
      get "/api/v1/daily_challenge"
    end

    assert_response :ok
    assert_equal({ "day" => "2026-12-05", "attempt" => nil }, response.parsed_body)
  end

  test "starting the challenge returns a draft marked as today's challenge" do
    travel_to Time.utc(2026, 12, 5, 12) do
      post "/api/v1/daily_challenge/attempt"
    end

    assert_response :created
    assert_equal "2026-12-05", response.parsed_body.dig("daily_challenge", "day")
    assert response.parsed_body["owned"]
  end

  test "starting again returns the same attempt" do
    travel_to Time.utc(2026, 12, 5, 12) do
      post "/api/v1/daily_challenge/attempt"
      first = response.parsed_body["id"]
      post "/api/v1/daily_challenge/attempt"

      assert_response :ok
      assert_equal first, response.parsed_body["id"]
      get "/api/v1/daily_challenge"
      assert_equal first, response.parsed_body.dig("attempt", "id")
    end
  end

  test "players in different browsers get their own attempts at the same seed" do
    ids = Array.new(2) do
      reset!
      travel_to(Time.utc(2026, 12, 5, 12)) { post "/api/v1/daily_challenge/attempt" }
      response.parsed_body["id"]
    end

    assert_not_equal ids.first, ids.last
    assert_equal 1, Draft.where(id: ids).distinct.count(:seed)
  end

  test "ordinary drafts are not marked as challenges" do
    post "/api/v1/drafts"

    assert_nil response.parsed_body["daily_challenge"]
  end
end
