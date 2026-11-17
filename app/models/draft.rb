# One playthrough: six spins, six picks, then a simulated title run.
#
# The seed drives every random choice in the draft (spins and fights), so the
# same draft always plays out the same way and can be replayed or shared.
class Draft < ApplicationRecord
  SEED_RANGE = 1...(2**62)

  enum :status, { in_progress: "in_progress", completed: "completed" }, validate: true

  # Only the default is declared, so the bigint column type is kept.
  attribute :seed, default: -> { SecureRandom.random_number(SEED_RANGE) }

  validates :seed, numericality: { only_integer: true, in: SEED_RANGE }
  validates :overall, numericality: { only_integer: true, in: FighterRating::RANGE }, allow_nil: true
  validates :wins, :losses, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :overall, :wins, :losses, :completed_at, presence: true, if: :completed?

  def record = completed? ? "#{wins}-#{losses}" : nil
  def undefeated? = completed? && losses.zero?
end
