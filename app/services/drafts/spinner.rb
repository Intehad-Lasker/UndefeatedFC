module Drafts
  # Chooses the weight class and era for a draft's next round.
  #
  # A pool qualifies when it is big enough that MIN_CHOICES fighters remain
  # even if every other pick in the draft came from it, and it has not already
  # come up in this draft. Eligibility depends only on the data and the draft's
  # own history, and the random choice comes from the draft's seed, so the same
  # seed always spins the same pools.
  class Spinner
    MIN_CHOICES = 8
    MIN_POOL_SIZE = MIN_CHOICES + Skills.all.size

    # rng and pool_sizes are injectable so tests control randomness and data.
    def initialize(draft, rng: nil, pool_sizes: -> { Fighter.pool_sizes })
      @draft = draft
      @rng = rng
      @pool_sizes = pool_sizes
    end

    # Returns the new DraftRound.
    def call
      @draft.transaction do
        @draft.lock_with_rounds!
        ensure_can_spin!
        weight_class_id, era_id = eligible_pools.sample(random: rng)
        @draft.rounds.create!(number: @draft.next_round_number, weight_class_id: weight_class_id, era_id: era_id)
      end
    rescue ActiveRecord::RecordNotUnique
      raise RuleViolation, "Pick a fighter before spinning again."
    end

    private

    def ensure_can_spin!
      raise RuleViolation, "This draft is already finished." if @draft.completed?
      raise RuleViolation, "Pick a fighter before spinning again." if @draft.open_round
      raise RuleViolation, "Every slot is already filled." if @draft.all_slots_filled?
      raise RuleViolation, "There are no pools left to spin." if eligible_pools.empty?
    end

    # Sorted so the seeded choice does not depend on database row order.
    def eligible_pools
      @eligible_pools ||= @pool_sizes.call
        .select { |_pool, size| size >= MIN_POOL_SIZE }
        .keys.sort - @draft.used_pools
    end

    def rng
      @rng ||= Random.new(@draft.seed + @draft.next_round_number)
    end
  end
end
