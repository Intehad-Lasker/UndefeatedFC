# Tells everyone watching that a board changed. Runs as a job so a slow or
# failing broadcast can never turn a successful pick into an error.
class LeaderboardBroadcastJob < ApplicationJob
  queue_as :default

  def perform(draft_id)
    draft = Draft.includes(:daily_challenge).find_by(id: draft_id)
    return unless draft&.completed? && draft.user_id # only named players appear on boards

    if draft.challenge?
      LeaderboardChannel.broadcast_to_board("daily", day: draft.daily_challenge.day)
    end
    LeaderboardChannel.broadcast_to_board("all_time")
  end
end
