# One execution of the scraper. The scraper inserts a running row, then marks it
# succeeded or failed. Rails reads succeeded runs to decide when to recompute
# ratings, so the two programs only share the database, not code.
class IngestionRun < ApplicationRecord
  enum :status, { running: "running", succeeded: "succeeded", failed: "failed" }, validate: true

  validates :source, :started_at, presence: true
  validates :events_count, :bouts_count, :fighters_count,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :finishes_after_start

  scope :recent_first, -> { order(started_at: :desc) }
  scope :awaiting_ratings, -> { succeeded.where(ratings_refreshed_at: nil) }

  def duration
    finished_at && (finished_at - started_at)
  end

  private

  def finishes_after_start
    return if finished_at.nil? || started_at.nil? || finished_at >= started_at

    errors.add(:finished_at, "must be after the start time")
  end
end
