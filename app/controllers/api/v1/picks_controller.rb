module Api
  module V1
    # POST /api/v1/drafts/:draft_id/picks with { pick: { fighter_id, slot } }.
    # The pick that fills the last slot also returns the finished result.
    class PicksController < BaseController
      include OwnedDraft
      include DraftRendering

      def create
        # A missing key is a malformed request (400); a bad value is a rule violation (422).
        fighter_id, slot = params.require(:pick).require(%i[fighter_id slot])
        Drafts::PickRecorder.new(@draft, fighter_id: fighter_id, slot: slot).call
        render_draft(@draft.id, status: :created)
      end
    end
  end
end
