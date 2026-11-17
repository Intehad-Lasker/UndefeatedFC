# Fights two builds against each other: up to five rounds, first to three wins.
# Each round is won with the same logistic curve as the solo title run
# (FightSimulator.win_probability), so one rating scale means the same thing in
# both modes. The generator is injected, so a match's seed fixes the result.
class HeadToHeadSimulator
  ROUNDS = 5
  ROUNDS_TO_WIN = 3

  Round = Data.define(:number, :winner_seat, :seat_one_chance)
  Result = Data.define(:rounds, :winner_seat) do
    def score = "#{rounds.count { |r| r.winner_seat == winner_seat }}-#{rounds.count { |r| r.winner_seat != winner_seat }}"
  end

  def initialize(rng:)
    @rng = rng
  end

  def call(overall_one, overall_two)
    chance = FightSimulator.win_probability(overall_one, overall_two)
    won = { 1 => 0, 2 => 0 }
    rounds = []

    ROUNDS.times do |index|
      winner = @rng.rand < chance ? 1 : 2
      won[winner] += 1
      rounds << Round.new(number: index + 1, winner_seat: winner, seat_one_chance: chance.round(3))
      break if won[winner] == ROUNDS_TO_WIN
    end

    Result.new(rounds: rounds, winner_seat: won.max_by { |_seat, count| count }.first)
  end
end
