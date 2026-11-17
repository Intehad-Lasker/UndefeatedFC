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

  # The player's existing attempt: the account's when signed in, otherwise this
  # browser's (even if an account has since claimed it, since the browser
  # already used its one attempt).
  def attempt_for(player_id:, user: nil)
    return drafts.find_by(player_id: player_id) unless user

    drafts.find_by(user: user) || drafts.find_by(player_id: player_id, user_id: nil)
  end

  # One attempt per player: returns the existing one or starts it. The partial
  # unique indexes settle a double-click race; the loser reads the winner's row.
  def attempt!(player_id:, user: nil)
    attempt_for(player_id: player_id, user: user) || start_draft!(player_id: player_id, user: user)
  rescue ActiveRecord::RecordNotUnique
    attempt_for(player_id: player_id, user: user)
  end
end
