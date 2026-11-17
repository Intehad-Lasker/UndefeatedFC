require "test_helper"

class Api::V1::MatchesControllerTest < ActionDispatch::IntegrationTest
  include PoolBuilder

  setup do
    %i[lightweight welterweight].product(%i[mainstream modern current]).each do |wc, era|
      fill_pool(weight_class: weight_classes(wc), era: eras(era), fighters: 24)
    end
  end

  def as_host = @host ||= open_session
  def as_guest = @guest ||= open_session

  def start_match
    as_host.post "/api/v1/matches"
    id = as_host.response.parsed_body["id"]
    as_guest.post "/api/v1/matches/#{id}/join"
    id
  end

  test "creating a match seats the host and waits for an opponent" do
    as_host.post "/api/v1/matches"

    body = as_host.response.parsed_body
    assert_equal 201, as_host.response.status
    assert_equal [ "waiting", 1 ], body.values_at("status", "your_seat")
    assert_nil body["pool"]
    assert_not body.key?("seed")
  end

  test "joining from the invite link starts the draft with the first pool" do
    id = start_match

    body = as_guest.response.parsed_body
    assert_equal [ "drafting", 2, 1, 1 ], body.values_at("status", "your_seat", "current_seat", "round")
    assert body.dig("pool", "fighters").size >= 8
    assert_not body.dig("pool", "fighters").first.key?("rating")
    as_host.get "/api/v1/matches/#{id}"
    assert_equal 1, as_host.response.parsed_body["your_seat"]
  end

  test "players take turns and picks reveal ratings on their board" do
    id = start_match
    fighter = as_host.tap { |s| s.get "/api/v1/matches/#{id}" }.response.parsed_body.dig("pool", "fighters", 0)

    as_host.post "/api/v1/matches/#{id}/picks", params: { pick: { fighter_id: fighter["id"], slot: "power" } }, as: :json

    body = as_host.response.parsed_body
    assert_equal 201, as_host.response.status
    assert_equal 2, body["current_seat"]
    slot = body["boards"].first["slots"].find { |s| s["key"] == "power" }
    assert_equal fighter["id"], slot.dig("fighter", "id")
    assert_kind_of Integer, slot["rating"]
    assert_not_includes body.dig("pool", "fighters").pluck("id"), fighter["id"]
  end

  test "picking out of turn is a rule violation" do
    id = start_match
    fighter_id = as_guest.response.parsed_body.dig("pool", "fighters", 0, "id")

    as_guest.post "/api/v1/matches/#{id}/picks", params: { pick: { fighter_id: fighter_id, slot: "power" } }, as: :json

    assert_equal 422, as_guest.response.status
    assert_equal "It's your opponent's turn.", as_guest.response.parsed_body.dig("error", "message")
  end

  test "a full match: twelve picks produce a winner" do
    id = start_match
    sessions = { 1 => as_host, 2 => as_guest }
    open = { 1 => Skills.keys.dup, 2 => Skills.keys.dup }

    (1..Match::PICKS).each do |number|
      seat = Match.seat_for_pick(number)
      session = sessions[seat]
      session.get "/api/v1/matches/#{id}"
      fighter_id = session.response.parsed_body.dig("pool", "fighters", 0, "id")
      session.post "/api/v1/matches/#{id}/picks", params: { pick: { fighter_id: fighter_id, slot: open[seat].shift } }, as: :json
      assert_equal 201, session.response.status, session.response.body
    end

    result = as_host.response.parsed_body["result"]
    assert_equal "completed", as_host.response.parsed_body["status"]
    assert_includes [ 1, 2 ], result["winner_seat"]
    assert_match(/\A3-[0-2]\z/, result["score"])
  end

  test "spectators can watch but not pick or join a full match" do
    id = start_match
    spectator = open_session

    spectator.get "/api/v1/matches/#{id}"
    assert_nil spectator.response.parsed_body["your_seat"]

    spectator.post "/api/v1/matches/#{id}/picks", params: { pick: { fighter_id: 1, slot: "chin" } }, as: :json
    assert_equal 403, spectator.response.status

    spectator.post "/api/v1/matches/#{id}/join"
    assert_equal 422, spectator.response.status
  end

  test "a new browser's page-load reads never mint a player id" do
    match = Match.create!
    fresh = open_session

    # The calls a first page load makes. If any of them minted an id, parallel
    # requests could each set a different cookie and swap the browser's identity.
    [ "/api/v1/meta", "/api/v1/session", "/api/v1/daily_challenge", "/api/v1/drafts/#{drafts(:fresh).id}",
      "/api/v1/matches/#{match.id}" ].each do |path|
      fresh.get path
      assert_nil fresh.cookies[:player_id].presence, "#{path} minted a player id"
    end
  end
end
