module Drafts
  # Chooses the weight class and era for a draft's next round.
  #
  # A pool qualifies when it is big enough that MIN_CHOICES fighters remain
  # even if every other pick in the draft came from it, and it has not already
  # come up in this draft. The choice itself (seeded, order-independent) lives
  # in Pools::Chooser, shared with head-to-head matches.
  class Spinner
    MIN_CHOICES = Pools::Chooser::MIN_CHOICES
    MIN_POOL_SIZE = MIN_CHOICES + Skills.all.size

    # rng and pool_sizes are injectable so tests control randomness and data.
    def initialize(draft, rng: nil, pool_sizes: -> { Fighter.pool_sizes })
      @draft = draft
      @rng = rng
      @chooser = Pools::Chooser.new(min_pool_size: MIN_POOL_SIZE, pool_sizes: pool_sizes)
    end

    # Returns the new DraftRound.
    def call
      @draft.transaction do
        @draft.lock_with_rounds!
        ensure_can_spin!
        number = @draft.next_round_number
        weight_class_id, era_id = @chooser.choose(seed: @draft.seed, round: number, used: @draft.used_pools, rng: @rng)
        @draft.rounds.create!(number: number, weight_class_id: weight_class_id, era_id: era_id)
      end
    rescue ActiveRecord::RecordNotUnique
      raise RuleViolation, "Pick a fighter before spinning again."
    end

    private

    def ensure_can_spin!
      raise RuleViolation, "This draft is already finished." if @draft.completed?
      raise RuleViolation, "Pick a fighter before spinning again." if @draft.open_round
      raise RuleViolation, "Every slot is already filled." if @draft.all_slots_filled?
      raise RuleViolation, "There are no pools left to spin." if @chooser.eligible(used: @draft.used_pools).empty?
    end
  end
end
