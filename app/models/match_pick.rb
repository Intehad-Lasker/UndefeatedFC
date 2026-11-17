class MatchPick < ApplicationRecord
  belongs_to :match, touch: true # a pick changes the match's cache key
  belongs_to :fighter

  validates :number, numericality: { only_integer: true, in: 1..Match::PICKS }
  validates :seat, inclusion: { in: Match::SEATS }
  validates :slot, inclusion: { in: ->(_) { Skills.keys } }
  validates :rating, numericality: { only_integer: true, in: FighterRating::RANGE }
end
