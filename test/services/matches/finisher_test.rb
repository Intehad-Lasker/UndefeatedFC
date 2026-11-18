require "test_helper"

class Matches::FinisherTest < ActiveSupport::TestCase
  include MatchBuilder

  setup { @match, @roster = build_match }

  # Plays all twelve picks in snake order with the roster's fighters.
  def play_out
    slots = { 1 => Skills.keys.dup, 2 => Skills.keys.dup }
    (1..Match::PICKS).each do |number|
      seat = Match.seat_for_pick(number)
      pick(@match, seat == 1 ? HOST : GUEST, @roster[number - 1], slots[seat].shift)
    end
    @match.reload
  end

  test "the twelfth pick finishes the match with a winner and a fight log" do
    match = play_out

    assert match.completed?
    assert_includes Match::SEATS, match.winner_seat
    assert_equal %w[overalls rounds score], match.result.keys.sort
    assert_includes 3..5, match.result["rounds"].size
  end

  test "each side's overall is the average of its six ratings" do
    FighterRating.where(fighter: @roster.values_at(0, 3, 4, 7, 8, 11)).delete_all
    @roster.values_at(0, 3, 4, 7, 8, 11).each_with_index do |fighter, index|
      FighterRating.create!(fighter: fighter, skill: Skills.keys[index], value: 90)
    end

    assert_equal 90, play_out.result.dig("overalls", "1")
  end

  test "refuses to finish early" do
    pick(@match, HOST, @roster[0], "striking")

    assert_raises(Matches::RuleViolation, match: "isn't finished") do
      Matches::Finisher.new(Match.with_everything.find(@match.id)).call
    end
  end
end
