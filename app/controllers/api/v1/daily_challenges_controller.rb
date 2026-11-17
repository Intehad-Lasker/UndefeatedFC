module Api
  module V1
    # GET /api/v1/daily_challenge: today's challenge and this player's attempt.
    class DailyChallengesController < BaseController
      def show
        @challenge = DailyChallenge.today
        @attempt = @challenge.attempt_for(player_id: current_player_id, user: current_user)
      end
    end
  end
end
