require "test_helper"

class Matches::PickRecorderTest < ActiveSupport::TestCase
  include MatchBuilder

  setup { @match, @roster = build_match }

  test "the host picks first and the pick records seat, slot and rating" do
    pick = pick(@match, HOST, @roster[0], "striking")

    assert_equal [ 1, 1, "striking" ], [ pick.number, pick.seat, pick.slot ]
    assert_kind_of Integer, pick.rating
  end

  test "turns follow snake order" do
    pick(@match, HOST, @roster[0], "striking")
    pick(@match, GUEST, @roster[1], "striking")
    pick(@match, GUEST, @roster[2], "power")

    assert_equal [ 1, 2, 2 ], MatchPick.where(match: @match).order(:number).pluck(:seat)
  end

  test "picking out of turn is refused" do
    assert_raises(Matches::RuleViolation, match: "opponent's turn") { pick(@match, GUEST, @roster[0], "striking") }
  end

  test "a fighter taken by the opponent can't be picked" do
    pick(@match, HOST, @roster[0], "striking")

    assert_raises(Matches::RuleViolation, match: "already been drafted") { pick(@match, GUEST, @roster[0], "power") }
  end

  test "a player can't fill the same slot twice, but the opponent can use it" do
    pick(@match, HOST, @roster[0], "striking")
    pick(@match, GUEST, @roster[1], "striking")
    pick(@match, GUEST, @roster[2], "power")

    assert_raises(Matches::RuleViolation, match: "Striking slot is already filled") { pick(@match, HOST, @roster[3], "striking") }
  end

  test "fighters from outside this round's pool are refused" do
    assert_raises(Matches::RuleViolation, match: "isn't in this round's pool") { pick(@match, HOST, fighters(:wrestler), "striking") }
  end

  test "spectators can't pick" do
    assert_raises(Matches::RuleViolation, match: "not playing") do
      Matches::PickRecorder.new(Match.find(@match.id), player_id: SecureRandom.uuid, fighter_id: @roster[0].id, slot: "chin").call
    end
  end

  test "no picks before an opponent joins" do
    @match.update!(status: :waiting)

    assert_raises(Matches::RuleViolation, match: "Waiting for an opponent") { pick(@match, HOST, @roster[0], "chin") }
  end
end
