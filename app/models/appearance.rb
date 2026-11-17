# One fighter's side of a bout: whether they won and what they landed. A join
# table (rather than red/blue fighter columns on bouts) means "every fighter who
# fought at Lightweight in 2016-2020" is a single join instead of an OR.
class Appearance < ApplicationRecord
  FIGHTERS_PER_BOUT = 2

  belongs_to :bout
  belongs_to :fighter

  enum :outcome, { win: "win", loss: "loss", draw: "draw", no_contest: "no_contest" }, validate: true

  validates :fighter_id, uniqueness: { scope: :bout_id }
  validates :knockdowns, :sig_strikes_landed, :takedowns_landed, :submission_attempts,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :bout_has_room, on: :create

  private

  def bout_has_room
    return if bout_id.nil?

    taken = Appearance.where(bout_id: bout_id).count
    errors.add(:bout, "already has #{FIGHTERS_PER_BOUT} fighters") if taken >= FIGHTERS_PER_BOUT
  end
end
