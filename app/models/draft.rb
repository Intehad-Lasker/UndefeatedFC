# One playthrough: six spins, six picks, then a simulated title run.
#
# The seed drives every random choice in the draft (spins and fights), so the
# same draft always plays out the same way and can be replayed or shared.
class Draft < ApplicationRecord
  SEED_RANGE = 1...(2**62)

  has_many :rounds, -> { order(:number) }, class_name: "DraftRound", inverse_of: :draft, dependent: :delete_all

  enum :status, { in_progress: "in_progress", completed: "completed" }, validate: true

  # Only the default is declared, so the bigint column type is kept.
  attribute :seed, default: -> { SecureRandom.random_number(SEED_RANGE) }

  validates :seed, numericality: { only_integer: true, in: SEED_RANGE }
  validates :overall, numericality: { only_integer: true, in: FighterRating::RANGE }, allow_nil: true
  validates :wins, :losses, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :overall, :wins, :losses, :completed_at, presence: true, if: :completed?

  scope :with_rounds, -> { includes(rounds: %i[weight_class era fighter]) }

  def record = completed? ? "#{wins}-#{losses}" : nil
  def undefeated? = completed? && losses.zero?

  # The helpers below read the loaded rounds. Load drafts with .with_rounds,
  # or call lock_with_rounds! inside a transaction before changing one.

  def open_round = rounds.find { |round| !round.picked? }
  def picked_rounds = rounds.select(&:picked?)
  def filled_slots = picked_rounds.map(&:slot)
  def open_slots = Skills.keys - filled_slots
  def drafted_fighter_ids = picked_rounds.map(&:fighter_id)
  def used_pools = rounds.map { |round| [ round.weight_class_id, round.era_id ] }
  def all_slots_filled? = open_slots.empty?
  def next_round_number = rounds.size + 1

  # Locks this draft's row (SELECT ... FOR UPDATE) and reloads its rounds, so
  # two requests changing the same draft run one after the other.
  def lock_with_rounds!
    lock!
    ActiveRecord::Associations::Preloader.new(records: [ self ], associations: { rounds: %i[weight_class era] }).call
    self
  end
end
