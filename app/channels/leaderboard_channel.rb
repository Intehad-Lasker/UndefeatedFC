# Pushes a nudge to everyone watching a leaderboard when it changes. The message
# only says which board moved; clients refetch it from the cached endpoint, so
# there is one source of truth for rankings.
class LeaderboardChannel < ApplicationCable::Channel
  BOARDS = %w[daily all_time].freeze

  def self.stream_for_board(board) = "leaderboard:#{board}"

  def self.broadcast_to_board(board, **details)
    ActionCable.server.broadcast(stream_for_board(board), { board: board, **details })
  end

  def subscribed
    board = params[:board].to_s
    return reject unless BOARDS.include?(board)

    stream_from self.class.stream_for_board(board)
  end
end
