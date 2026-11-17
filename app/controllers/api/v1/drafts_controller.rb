module Api
  module V1
    class DraftsController < BaseController
      include DraftRendering

      def create
        draft = Draft.create!(player_id: current_player_id)
        render_draft(draft.id, status: :created)
      end

      def show
        render_draft(params[:id])
      end
    end
  end
end
