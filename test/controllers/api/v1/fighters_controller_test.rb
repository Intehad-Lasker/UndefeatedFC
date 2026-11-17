require "test_helper"

class Api::V1::FightersControllerTest < ActionDispatch::IntegrationTest
  test "search returns matching fighters with their UFC record" do
    get "/api/v1/fighters", params: { q: "vance" }

    assert_response :ok
    fighters = response.parsed_body["fighters"]
    assert_equal [ "Rico Vance" ], fighters.pluck("name")
    assert_equal 3, fighters.first.dig("ufc_record", "fights")
  end

  test "search tolerates typos" do
    get "/api/v1/fighters", params: { q: "ferriera" }

    assert_equal [ "Tomas Ferreira" ], response.parsed_body["fighters"].pluck("name")
  end

  test "an empty search returns no fighters" do
    get "/api/v1/fighters"

    assert_equal [], response.parsed_body["fighters"]
  end

  test "search results never include ratings" do
    get "/api/v1/fighters", params: { q: "vance" }

    assert_not response.parsed_body.to_s.include?("rating")
  end

  test "profile lists recent bouts, newest first, with opponent and result" do
    get "/api/v1/fighters/#{fighters(:striker).id}"

    assert_response :ok
    bouts = response.parsed_body["recent_bouts"]
    assert_equal %w[loss loss win], bouts.pluck("outcome")
    assert_equal "Tomas Ferreira", bouts.first.dig("opponent", "name")
    assert_equal "submission", bouts.first["finish"]
  end

  test "profile lists the pools the fighter can be drafted from" do
    get "/api/v1/fighters/#{fighters(:striker).id}"

    pools = response.parsed_body["pools"].map { |pool| pool.values_at("weight_class", "era") }
    assert_equal [ %w[Lightweight Mainstream], %w[Lightweight Modern], %w[Welterweight Current] ], pools
  end

  test "an unknown fighter is a 404" do
    get "/api/v1/fighters/0"

    assert_response :not_found
    assert_equal "That fighter does not exist.", response.parsed_body.dig("error", "message")
  end
end
