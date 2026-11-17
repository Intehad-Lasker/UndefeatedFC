# Plays a 15-fight title run for a build with a given overall rating.
#
# Opponents get steadily tougher, from 55 to 88. Each fight is won with
# probability 1 / (1 + e^(-(overall - opponent) / SPREAD)): an even matchup is a
# coin flip, a 12-point edge wins about 88% of the time. Tuned so an overall of
# 90 goes 15-0 about 15% of the time, 85 about 2.5%, and 80 almost never.
# Randomness comes from an injected generator, so a seeded draft always gets
# the same record.
class FightSimulator
  FIGHTS = 15
  EASIEST_OPPONENT = 55
  TOUGHEST_OPPONENT = 88
  SPREAD = 6.0

  Fight = Data.define(:number, :opponent_rating, :win_probability, :won)

  Result = Data.define(:fights) do
    def wins = fights.count(&:won)
    def losses = fights.size - wins
    def undefeated? = losses.zero?
  end

  def self.opponent_ratings
    step = (TOUGHEST_OPPONENT - EASIEST_OPPONENT).fdiv(FIGHTS - 1)
    Array.new(FIGHTS) { |index| (EASIEST_OPPONENT + (step * index)).round }
  end

  def self.win_probability(overall, opponent_rating)
    1.0 / (1 + Math.exp(-(overall - opponent_rating) / SPREAD))
  end

  def initialize(rng:)
    @rng = rng
  end

  def call(overall)
    fights = self.class.opponent_ratings.each_with_index.map do |opponent, index|
      probability = self.class.win_probability(overall, opponent)
      Fight.new(number: index + 1, opponent_rating: opponent, win_probability: probability.round(3), won: @rng.rand < probability)
    end
    Result.new(fights: fights)
  end
end
