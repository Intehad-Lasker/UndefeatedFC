# The challenge for one UTC day. Every player's challenge draft uses its seed,
# so everyone gets the same six spins.
class DailyChallenge < ApplicationRecord
  has_many :drafts, dependent: :restrict_with_error

  attribute :seed, default: -> { SecureRandom.random_number(Draft::SEED_RANGE) }

  # No uniqueness validation on purpose: create_or_find_by! needs the insert to
  # reach the unique index and raise RecordNotUnique. A validation would fail
  # first with RecordInvalid, which create_or_find_by! does not rescue.
  validates :day, presence: true
  validates :seed, numericality: { only_integer: true, in: Draft::SEED_RANGE }

  # Today's challenge, created on first use. create_or_find_by! leans on the
  # unique index, so two requests racing at midnight still get one challenge.
  def self.for_day(day = Time.now.utc.to_date)
    create_or_find_by!(day: day)
  end

  def self.today = for_day

  # A player's attempt. It copies the challenge's seed, which is all it takes
  # for the Spinner and FightSimulator to give everyone the same six spins.
  def start_draft!(player_id:, user: nil)
    drafts.create!(seed: seed, player_id: player_id, user: user)
  end
end
