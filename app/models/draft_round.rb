# One spin of a draft: the weight class and era it landed on, and (once picked)
# the fighter chosen and the slot they fill.
class DraftRound < ApplicationRecord
  belongs_to :draft, touch: true # a spin or pick changes the draft's cache key
  belongs_to :weight_class
  belongs_to :era
  belongs_to :fighter, optional: true

  validates :number, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :slot, inclusion: { in: ->(_) { Skills.keys } }, allow_nil: true
  validates :rating, numericality: { only_integer: true, in: FighterRating::RANGE }, allow_nil: true
  validates :fighter, :slot, :rating, :picked_at, presence: true, if: :picked?

  scope :open, -> { where(fighter_id: nil) }
  scope :picked, -> { where.not(fighter_id: nil) }

  def picked? = fighter_id.present?
end
