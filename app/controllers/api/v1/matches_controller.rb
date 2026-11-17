module Api
  module V1
    # Head-to-head matches. The match id is the invite link; anyone with it can
    # watch, the first other visitor to join takes seat 2, and only the two
    # players can pick.
    class MatchesController < BaseController
      rate_limit to: DraftsController::CREATE_LIMIT, within: 1.minute, only: :create,
        store: Rails.configuration.x.rate_limit_store || Rails.cache,
        with: -> { render_error :too_many_requests, "rate_limited", "You're starting matches too quickly. Try again in a minute." }

      def create
        match = Matches::Creator.new(player_id: current_player_id, user: current_user).call
        render_match(match.id, status: :created)
      end

      def show
        render_match(params[:id])
      end

      def join
        Matches::Joiner.new(Match.find(params[:id]), player_id: current_player_id, user: current_user).call
        render_match(params[:id])
      end

      def pick
        match = Match.with_everything.find(params[:id])
        unless match.player_for(player_id: current_player_id, user: current_user)
          raise Forbidden, "Only the two players in this match can pick."
        end

        fighter_id, slot = params.require(:pick).require(%i[fighter_id slot])
        Matches::PickRecorder.new(match, player_id: current_player_id, user: current_user, fighter_id: fighter_id, slot: slot).call
        render_match(match.id, status: :created)
      end

      private

      def render_match(id, status: :ok)
        @match = Match.with_everything.find(id)
        @you = @match.player_for(player_id: current_player_id, user: current_user)
        @pool = @match.current_pool
        if @pool
          @weight_class = WeightClass.find(@pool[:weight_class_id])
          @era = Era.find(@pool[:era_id])
          @fighters = Fighter.in_pool(weight_class: @weight_class, era: @era)
            .where.not(id: @match.drafted_fighter_ids).with_ufc_record.order(:name)
        end
        render "api/v1/matches/show", status: status
      end
    end
  end
end
