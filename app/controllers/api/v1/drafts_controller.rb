module Api
  module V1
    class DraftsController < BaseController
      include DraftRendering

      CREATE_LIMIT = 20
      HISTORY_LIMIT = 50

      before_action :require_authentication, only: :index

      # Rails' built-in limiter, counted per IP in the cache store (Solid Cache in
      # production), so scripts can't flood the drafts table.
      rate_limit to: CREATE_LIMIT, within: 1.minute, only: :create,
        store: Rails.configuration.x.rate_limit_store || Rails.cache,
        with: -> { render_error :too_many_requests, "rate_limited", "You're starting drafts too quickly. Try again in a minute." }

      # GET /api/v1/drafts: the signed-in player's drafts, newest first.
      def index
        @drafts = current_user.drafts.with_pick_counts.order(created_at: :desc).limit(HISTORY_LIMIT)
      end

      def create
        draft = Draft.create!(player_id: current_player_id, user: current_user)
        render_draft(draft.id, status: :created)
      end

      # Conditional GET: unchanged drafts answer 304 without rendering. The ETag
      # covers the draft (rounds touch it), who is asking (the owned flag), and
      # fighter data (the open round's pool).
      def show
        draft = Draft.find(params[:id])
        owned = draft.played_by?(current_player_id, current_user)
        render_draft(draft.id) if stale?(etag: [ draft, owned, Fighter.maximum(:updated_at) ])
      end
    end
  end
end
