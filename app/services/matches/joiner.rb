module Matches
  # Takes seat 2 from an invite link. The row lock means two people racing for
  # the last seat can't both get it; opening your own link again is harmless.
  class Joiner
    def initialize(match, player_id:, user: nil)
      @match = match
      @player_id = player_id
      @user = user
    end

    def call
      @match.with_lock do
        players = MatchPlayer.where(match: @match).to_a
        existing = players.find { |player| player.player_id == @player_id || (@user && player.user_id == @user.id) }
        next existing if existing
        raise RuleViolation, "This match already has two players." unless @match.waiting? && players.size == 1

        player = MatchPlayer.create!(match: @match, seat: 2, player_id: @player_id, user: @user,
                                     display_name: @user&.display_name || "Player 2")
        @match.update!(status: :drafting)
        player
      end
    end
  end
end
