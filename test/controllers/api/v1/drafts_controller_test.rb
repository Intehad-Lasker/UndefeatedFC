require "test_helper"

class Api::V1::DraftsControllerTest < ActionDispatch::IntegrationTest
  test "create starts an empty draft owned by this browser" do
    post "/api/v1/drafts"

    assert_response :created
    body = response.parsed_body
    assert_equal "in_progress", body["status"]
    assert body["owned"]
    assert_equal Skills.keys, body["slots"].pluck("key")
    assert body["slots"].all? { |slot| slot["fighter"].nil? }
    assert_nil body["open_round"]
  end

  test "never exposes the seed" do
    post "/api/v1/drafts"

    assert_not response.parsed_body.key?("seed")
  end

  test "show returns rounds, the filled slot and the open round's pool" do
    get "/api/v1/drafts/#{drafts(:fresh).id}"

    assert_response :ok
    body = response.parsed_body
    assert_equal [ 1, 2 ], body["rounds"].pluck("number")
    assert_equal [ 95, "Rico Vance" ], [ body["slots"].first["rating"], body["slots"].first.dig("fighter", "name") ]
    assert_equal "Lightweight", body.dig("open_round", "weight_class", "name")
    assert_equal "Mainstream (2011-2015)", body.dig("open_round", "era", "label")
  end

  test "the pool leaves out fighters already drafted and hides ratings" do
    get "/api/v1/drafts/#{drafts(:fresh).id}"

    pool = response.parsed_body.dig("open_round", "pool")
    assert_equal [ "Tomas Ferreira" ], pool.pluck("name")
    assert_not pool.first.key?("rating")
    assert_equal 2, pool.first.dig("ufc_record", "fights")
  end

  test "a picked round reveals the fighter's rating" do
    get "/api/v1/drafts/#{drafts(:fresh).id}"

    first_round = response.parsed_body["rounds"].first
    assert_equal [ true, "striking", 95 ], first_round.values_at("picked", "slot", "rating")
  end

  test "a finished draft includes its result" do
    get "/api/v1/drafts/#{drafts(:undefeated).id}"

    result = response.parsed_body["result"]
    assert_equal [ 91, "15-0", true ], result.values_at("overall", "record", "undefeated")
  end

  test "another browser can view a draft but does not own it" do
    get "/api/v1/drafts/#{drafts(:fresh).id}"

    assert_not response.parsed_body["owned"]
  end

  test "an unknown draft is a 404" do
    get "/api/v1/drafts/#{SecureRandom.uuid}"

    assert_response :not_found
    assert_equal "not_found", response.parsed_body.dig("error", "code")
  end
end
