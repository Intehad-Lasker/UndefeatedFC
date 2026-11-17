module Api
  module V1
    # Shared by every endpoint that returns a draft, so creating, viewing,
    # spinning and picking all respond with the same full draft state.
    module DraftRendering
      private

      def render_draft(id, status: :ok)
        @draft = Draft.with_rounds.find(id)
        @pool = pool_for(@draft)
        @owned = @draft.played_by?(current_player_id)
        render "api/v1/drafts/show", status: status
      end

      # Fighters still available in the open round, without their ratings.
      def pool_for(draft)
        round = draft.open_round
        return Fighter.none unless round

        Fighter.in_pool(weight_class: round.weight_class, era: round.era)
          .where.not(id: draft.drafted_fighter_ids)
          .with_ufc_record
          .order(:name)
      end
    end
  end
end
