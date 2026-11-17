module Api
  module V1
    # POST /api/v1/drafts/:draft_id/rounds spins the next round. The server
    # chooses the pool; the frontend only animates the result.
    class RoundsController < BaseController
      include OwnedDraft
      include DraftRendering

      def create
        Drafts::Spinner.new(@draft).call
        render_draft(@draft.id, status: :created)
      end
    end
  end
end
