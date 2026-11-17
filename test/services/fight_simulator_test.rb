require "test_helper"

class FightSimulatorTest < ActiveSupport::TestCase
  def simulate(overall, seed: 1) = FightSimulator.new(rng: Random.new(seed)).call(overall)

  test "fights fifteen opponents from 55 up to 88" do
    ratings = FightSimulator.opponent_ratings

    assert_equal 15, ratings.size
    assert_equal [ 55, 88 ], ratings.values_at(0, -1)
    assert_equal ratings.sort, ratings
  end

  test "an even matchup is a coin flip and a big edge is a near-lock" do
    assert_in_delta 0.5, FightSimulator.win_probability(70, 70)
    assert_in_delta 0.88, FightSimulator.win_probability(82, 70), 0.01
    assert_operator FightSimulator.win_probability(40, 92), :<, 0.01
  end

  test "the same seed gives the same record" do
    assert_equal simulate(75, seed: 9), simulate(75, seed: 9)
  end

  test "wins and losses add up to fifteen" do
    result = simulate(70)

    assert_equal 15, result.wins + result.losses
    assert_equal (1..15).to_a, result.fights.map(&:number)
  end

  test "better builds win more on average" do
    average = ->(overall) { (1..200).sum { |seed| simulate(overall, seed: seed).wins } / 200.0 }

    assert_operator average.call(90), :>, average.call(70)
    assert_operator average.call(70), :>, average.call(50)
  end

  test "an elite build often goes undefeated and a weak one never does" do
    elite = (1..200).count { |seed| simulate(99, seed: seed).undefeated? }
    weak = (1..200).count { |seed| simulate(30, seed: seed).undefeated? }

    assert_operator elite, :>, 0
    assert_equal 0, weak
  end

  test "records each fight's opponent, odds and result" do
    fight = simulate(80).fights.first

    assert_equal 55, fight.opponent_rating
    assert_in_delta FightSimulator.win_probability(80, 55), fight.win_probability, 0.001
    assert_includes [ true, false ], fight.won
  end
end
