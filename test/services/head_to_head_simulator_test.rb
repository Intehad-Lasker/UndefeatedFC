require "test_helper"

class HeadToHeadSimulatorTest < ActiveSupport::TestCase
  def fight(one, two, seed: 1) = HeadToHeadSimulator.new(rng: Random.new(seed)).call(one, two)

  test "stops as soon as someone wins three rounds" do
    result = fight(70, 70)
    wins = result.rounds.count { |round| round.winner_seat == result.winner_seat }

    assert_equal 3, wins
    assert_includes 3..5, result.rounds.size
  end

  test "the same seed gives the same fight" do
    assert_equal fight(75, 72, seed: 9), fight(75, 72, seed: 9)
  end

  test "the stronger build wins far more often" do
    stronger = (1..300).count { |seed| fight(85, 65, seed: seed).winner_seat == 1 }

    assert_operator stronger, :>, 270
  end

  test "evenly matched builds split close to fifty-fifty" do
    seat_one = (1..400).count { |seed| fight(75, 75, seed: seed).winner_seat == 1 }

    assert_includes 160..240, seat_one
  end

  test "score reads winner-first" do
    result = fight(99, 10)

    assert_equal "3-0", result.score
  end
end
