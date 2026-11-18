# Live updates for one match: both players (and anyone watching the link) get a
# nudge when someone joins or picks, then refetch the match from the API.
class MatchChannel < ApplicationCable::Channel
  def self.stream_for_match(match_id) = "match:#{match_id}"

  def self.broadcast_change(match_id)
    ActionCable.server.broadcast(stream_for_match(match_id), { match_id: match_id })
  end

  def subscribed
    match_id = params[:id].to_s
    return reject unless Match.exists?(id: match_id)

    stream_from self.class.stream_for_match(match_id)
  rescue ActiveRecord::StatementInvalid # not a UUID
    reject
  end
end
