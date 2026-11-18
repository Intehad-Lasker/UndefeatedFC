module Pools
  # Picks the weight class and era for a round, reproducibly.
  #
  # A pool qualifies when it has at least min_pool_size fighters and has not
  # been used yet. Pools are sorted before the seeded choice, so the result
  # never depends on database row order: the same seed and round always give
  # the same pool. Shared by solo drafts and head-to-head matches.
  class Chooser
    MIN_CHOICES = 8 # fighters a player can still choose from at worst

    # pool_sizes is injectable so tests control the data.
    def initialize(min_pool_size:, pool_sizes: -> { Fighter.pool_sizes })
      @min_pool_size = min_pool_size
      @pool_sizes = pool_sizes
    end

    def eligible(used: [])
      @eligible ||= @pool_sizes.call.select { |_pool, size| size >= @min_pool_size }.keys.sort
      @eligible - used
    end

    # [weight_class_id, era_id], or nil when no pool is left.
    def choose(seed:, round:, used: [], rng: nil)
      eligible(used: used).sample(random: rng || Random.new(seed + round))
    end
  end
end
