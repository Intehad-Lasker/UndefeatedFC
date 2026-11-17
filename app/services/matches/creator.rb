module Matches
  # Starts a match in seat 1 and fixes its six round pools up front, so both
  # players see the same pools no matter what data changes mid-match.
  class Creator
    # Each pool must leave MIN_CHOICES fighters even if all twelve picks came from it.
    MIN_POOL_SIZE = Pools::Chooser::MIN_CHOICES + Match::PICKS

    def initialize(player_id:, user: nil, pool_sizes: -> { Fighter.pool_sizes })
      @player_id = player_id
      @user = user
      @chooser = Pools::Chooser.new(min_pool_size: MIN_POOL_SIZE, pool_sizes: pool_sizes)
    end

    def call
      match = Match.new
      pools = choose_pools(match.seed)

      Match.transaction do
        match.update!(pools: pools)
        match.players.create!(seat: 1, player_id: @player_id, user: @user, display_name: @user&.display_name || "Player 1")
      end
      Match.with_everything.find(match.id)
    end

    private

    def choose_pools(seed)
      (1..Match::ROUNDS).each_with_object([]) do |round, chosen|
        pool = @chooser.choose(seed: seed, round: round, used: chosen)
        raise RuleViolation, "There isn't enough fighter data to start a match yet." unless pool

        chosen << pool
      end
    end
  end
end
