module Matches
  # Ends a match once all twelve picks are in: each build's overall is the
  # average of its six ratings, then the builds fight with the match's seed.
  class Finisher
    def initialize(match, simulator: HeadToHeadSimulator.new(rng: Random.new(match.seed)))
      @match = match
      @simulator = simulator
    end

    # Expects players and picks to be loaded. Returns the simulator result.
    def call
      raise RuleViolation, "The draft isn't finished yet." unless @match.picks.size == Match::PICKS

      overalls = Match::SEATS.to_h { |seat| [ seat, overall_for(seat) ] }
      result = @simulator.call(overalls[1], overalls[2])
      @match.update!(
        status: :completed, winner_seat: result.winner_seat, completed_at: Time.current,
        result: { overalls: overalls, score: result.score, rounds: result.rounds.map(&:to_h) }
      )
      result
    end

    private

    def overall_for(seat)
      @match.picks_for(seat).sum(&:rating).fdiv(Skills.all.size).round
    end
  end
end
