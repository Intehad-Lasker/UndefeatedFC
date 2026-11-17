module Api
  module V1
    # Loads the draft from params[:draft_id] and refuses anyone but the browser
    # that started it. Viewing a draft is public (share links); changing it is not.
    module OwnedDraft
      extend ActiveSupport::Concern

      included do
        before_action :set_owned_draft
      end

      private

      def set_owned_draft
        @draft = Draft.find(params[:draft_id])
        return if @draft.played_by?(current_player_id)

        raise BaseController::Forbidden, "Only the player who started this draft can change it."
      end
    end
  end
end
