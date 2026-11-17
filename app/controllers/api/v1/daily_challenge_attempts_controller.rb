module Api
  module V1
    # POST /api/v1/daily_challenge/attempt starts today's challenge for this
    # player, or returns their existing attempt (one per player per day).
    class DailyChallengeAttemptsController < BaseController
      include DraftRendering

      def create
        challenge = DailyChallenge.today
        existing = challenge.attempt_for(player_id: current_player_id, user: current_user)
        attempt = existing || challenge.attempt!(player_id: current_player_id, user: current_user)
        render_draft(attempt.id, status: existing ? :ok : :created)
      end
    end
  end
end
