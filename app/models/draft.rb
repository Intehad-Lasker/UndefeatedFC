# One playthrough: six spins, six picks, then a simulated title run.
#
# The seed drives every random choice in the draft (spins and fights), so the
# same draft always plays out the same way and can be replayed or shared.
class Draft < ApplicationRecord
  SEED_RANGE = 1...(2**62)

  belongs_to :user, optional: true
  belongs_to :daily_challenge, optional: true
  has_many :rounds, -> { order(:number) }, class_name: "DraftRound", inverse_of: :draft, dependent: :delete_all

  enum :status, { in_progress: "in_progress", completed: "completed" }, validate: true

  # Only the default is declared, so the bigint column type is kept.
  attribute :seed, default: -> { SecureRandom.random_number(SEED_RANGE) }

  validates :seed, numericality: { only_integer: true, in: SEED_RANGE }
  validates :overall, numericality: { only_integer: true, in: FighterRating::RANGE }, allow_nil: true
  validates :wins, :losses, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :overall, :wins, :losses, :completed_at, presence: true, if: :completed?

  scope :with_rounds, -> { includes(rounds: %i[weight_class era fighter]) }

  # Adds picks_made to each draft in one grouped query (for lists of drafts).
  scope :with_pick_counts, -> {
    left_joins(:rounds).select("drafts.*", "COUNT(draft_rounds.fighter_id) AS picks_made").group(:id)
  }

  # Guest drafts belong to the browser that started them; claimed drafts belong
  # to the account.
  def played_by?(player_id, user = nil)
    return user_id == user.id if user_id && user

    player_id.present? && self.player_id == player_id
  end

  # Moves a browser's guest drafts onto an account when that browser signs in.
  # Guest attempts at challenges the account already played stay with the
  # browser, so an account still has one attempt per challenge.
  def self.claim_for(user, player_id:)
    played = where(user: user).where.not(daily_challenge_id: nil).select(:daily_challenge_id)
    where(player_id: player_id, user_id: nil)
      .where("daily_challenge_id IS NULL OR daily_challenge_id NOT IN (?)", played)
      .update_all(user_id: user.id, updated_at: Time.current)
  end

  def challenge? = daily_challenge_id.present?

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
