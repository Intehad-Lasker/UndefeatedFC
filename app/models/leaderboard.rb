# Ranked, finished drafts by signed-in players (guests have no name to show).
#
# Order: most wins, then highest overall, then whoever finished first. RANK()
# gives tied records the same place, the way standings usually read.
class Leaderboard
  LIMIT = 50

  Entry = Data.define(:rank, :draft_id, :display_name, :wins, :losses, :overall, :completed_at) do
    def record = "#{wins}-#{losses}"
    def undefeated? = losses.zero?
  end

  # Everyone's attempt at one day's challenge.
  def self.daily(challenge, limit: LIMIT)
    new(Draft.completed.where(daily_challenge: challenge), limit: limit)
  end

  # Each player's single best run across all drafts. DISTINCT ON keeps the
  # first row per user under the ORDER BY, i.e. their best draft.
  def self.all_time(limit: LIMIT)
    best_per_player = Draft.completed.where.not(user_id: nil)
      .select("DISTINCT ON (drafts.user_id) drafts.*")
      .order("drafts.user_id, drafts.wins DESC, drafts.overall DESC, drafts.completed_at ASC")
    new(Draft.from(best_per_player, :drafts), limit: limit)
  end

  def initialize(scope, limit:)
    @scope = scope
    @limit = limit
  end

  def entries
    @scope.joins(:user)
      .select(
        "drafts.id", "users.display_name", "drafts.wins", "drafts.losses", "drafts.overall", "drafts.completed_at",
        "RANK() OVER (ORDER BY drafts.wins DESC, drafts.overall DESC) AS rank"
      )
      .order("rank", "drafts.completed_at")
      .limit(@limit)
      .map do |row|
        Entry.new(rank: row[:rank], draft_id: row.id, display_name: row[:display_name], wins: row.wins,
                  losses: row.losses, overall: row.overall, completed_at: row.completed_at)
      end
  end

  # Changes whenever a draft on this board finishes; used for cache keys and ETags.
  def version
    @scope.maximum(:completed_at)&.to_fs(:usec)
  end
end
