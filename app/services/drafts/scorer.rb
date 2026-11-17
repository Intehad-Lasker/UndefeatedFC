module Drafts
  # Finishes a draft once every slot is filled: the overall rating is the
  # average of the six slot ratings, and the title run is simulated with the
  # draft's own seed, so re-scoring the same draft always gives the same record.
  class Scorer
    def initialize(draft, simulator: FightSimulator.new(rng: Random.new(draft.seed)))
      @draft = draft
      @simulator = simulator
    end

    # Expects the draft's rounds to be loaded. Returns the FightSimulator::Result.
    def call
      raise RuleViolation, "Fill every slot before the title run." unless @draft.all_slots_filled?

      overall = @draft.picked_rounds.sum(&:rating).fdiv(Skills.all.size).round
      result = @simulator.call(overall)

      @draft.update!(
        status: :completed, overall: overall, wins: result.wins, losses: result.losses,
        fight_log: result.fights.map(&:to_h), completed_at: Time.current
      )
      # Only announce the result once it is committed; a rolled-back pick must
      # never reach anyone's leaderboard.
      draft_id = @draft.id
      ActiveRecord.after_all_transactions_commit { LeaderboardBroadcastJob.perform_later(draft_id) }
      result
    end
  end
end
