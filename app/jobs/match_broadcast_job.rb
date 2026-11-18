# Announces a change to a match after it has been committed.
class MatchBroadcastJob < ApplicationJob
  queue_as :default

  def perform(match_id)
    MatchChannel.broadcast_change(match_id)
  end
end
