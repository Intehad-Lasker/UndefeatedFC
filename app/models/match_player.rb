class MatchPlayer < ApplicationRecord
  belongs_to :match, touch: true
  belongs_to :user, optional: true

  validates :seat, inclusion: { in: Match::SEATS }
  validates :player_id, :display_name, presence: true
end
