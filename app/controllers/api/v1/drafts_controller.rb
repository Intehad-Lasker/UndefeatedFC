module Api
  module V1
    class DraftsController < BaseController
      include DraftRendering

      def create
        draft = Draft.create!(player_id: current_player_id)
        render_draft(draft.id, status: :created)
      end

      # Conditional GET: unchanged drafts answer 304 without rendering. The ETag
      # covers the draft (rounds touch it), who is asking (the owned flag), and
      # fighter data (the open round's pool).
      def show
        draft = Draft.find(params[:id])
        render_draft(draft.id) if stale?(etag: [ draft, draft.played_by?(current_player_id), Fighter.maximum(:updated_at) ])
      end
    end
  end
end
