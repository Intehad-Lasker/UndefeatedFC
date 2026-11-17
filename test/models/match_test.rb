require "test_helper"

class MatchTest < ActiveSupport::TestCase
  PLAYER_ONE = "11111111-0000-4000-8000-000000000001".freeze
  PLAYER_TWO = "11111111-0000-4000-8000-000000000002".freeze

  def match_with_players
    match = Match.create!(status: :drafting, pools: Array.new(6) { |i| [ weight_classes(:lightweight).id, eras(:modern).id + i ] })
    match.players.create!(seat: 1, player_id: PLAYER_ONE, display_name: "One")
    match.players.create!(seat: 2, player_id: PLAYER_TWO, display_name: "Two")
    Match.with_everything.find(match.id)
  end

  test "picks follow snake order so first choice alternates" do
    assert_equal [ 1, 2, 2, 1, 1, 2, 2, 1, 1, 2, 2, 1 ], (1..12).map { |n| Match.seat_for_pick(n) }
  end

  test "two picks per round" do
    assert_equal [ 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6 ], (1..12).map { |n| Match.round_for_pick(n) }
  end

  test "a new match gets a UUID, a seed and waits for an opponent" do
    match = Match.create!

    assert_match(/\A\h{8}-/, match.id)
    assert match.waiting?
    assert_includes Draft::SEED_RANGE, match.seed
  end

  test "tracks the current turn, seat and pool" do
    match = match_with_players

    assert_equal [ 1, 1, 1 ], [ match.next_pick_number, match.current_seat, match.current_round ]
    assert_equal({ weight_class_id: weight_classes(:lightweight).id, era_id: eras(:modern).id }, match.current_pool)
  end

  test "finds a player by browser or account" do
    match = match_with_players

    assert_equal 2, match.player_for(player_id: PLAYER_TWO).seat
    assert_nil match.player_for(player_id: "11111111-0000-4000-8000-000000000009")
  end

  test "a seat holds one player and a browser one seat" do
    match = match_with_players

    assert_raises(ActiveRecord::RecordNotUnique) { match.players.create!(seat: 1, player_id: SecureRandom.uuid, display_name: "X") }
    assert_raises(ActiveRecord::RecordNotUnique) { MatchPlayer.create!(match: match, seat: 2, player_id: PLAYER_ONE, display_name: "X") }
  end

  test "a fighter can be drafted once per match and each slot once per player" do
    match = match_with_players
    match.picks.create!(number: 1, seat: 1, fighter: fighters(:striker), slot: "striking", rating: 90)

    assert_raises(ActiveRecord::RecordNotUnique) do
      MatchPick.create!(match: match, number: 2, seat: 2, fighter: fighters(:striker), slot: "power", rating: 50)
    end
    assert_raises(ActiveRecord::RecordNotUnique) do
      MatchPick.create!(match: match, number: 3, seat: 1, fighter: fighters(:wrestler), slot: "striking", rating: 50)
    end
  end

  test "open slots are per player" do
    match = match_with_players
    match.picks.create!(number: 1, seat: 1, fighter: fighters(:striker), slot: "striking", rating: 90)
    match = Match.with_everything.find(match.id)

    assert_not_includes match.open_slots_for(1), "striking"
    assert_includes match.open_slots_for(2), "striking"
    assert_equal 2, match.current_seat
  end
end
