# A fighter's 0-99 rating in one skill, relative to every other fighter.
# Written in bulk by Ratings::Refresher; never edited by hand.
class FighterRating < ApplicationRecord
  RANGE = 0..99

  belongs_to :fighter

  validates :skill, inclusion: { in: ->(_) { Skills.keys } }
  validates :skill, uniqueness: { scope: :fighter_id }
  validates :value, numericality: { only_integer: true, in: RANGE }
end
