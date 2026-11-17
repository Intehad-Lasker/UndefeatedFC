module Api
  module V1
    # GET /api/v1/leaderboards/daily(?day=YYYY-MM-DD) and /all_time.
    #
    # Two layers of caching, both keyed on the board's version (the latest
    # completed_at): an ETag so browsers get a 304, and Solid Cache so the
    # ranking query runs once per change. A new result changes the version, so
    # nothing ever has to be expired by hand.
    class LeaderboardsController < BaseController
      CACHE_TTL = 1.hour

      rescue_from Date::Error do
        render_error :bad_request, "bad_request", "day must be a date like 2026-11-17."
      end

      def daily
        challenge = params[:day] ? DailyChallenge.find_by!(day: Date.iso8601(params[:day])) : DailyChallenge.today
        render_board Leaderboard.daily(challenge), key: [ "leaderboard", "daily", challenge.id ], day: challenge.day
      end

      def all_time
        render_board Leaderboard.all_time, key: [ "leaderboard", "all_time" ]
      end

      private

      def render_board(board, key:, day: nil)
        version = board.version
        return unless stale?(etag: [ key, version ], public: true)

        @day = day
        @entries = Rails.cache.fetch([ *key, version ], expires_in: CACHE_TTL) { board.entries.map(&:to_h) }
        render :show
      end
    end
  end
end
