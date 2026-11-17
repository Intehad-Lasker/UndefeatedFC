# One fight on an event card. The two fighters and their results live in
# appearances.
class Bout < ApplicationRecord
  belongs_to :event
  belongs_to :weight_class
  has_many :appearances, dependent: :destroy
  has_many :fighters, through: :appearances

  enum :finish, {
    ko_tko: "ko_tko",
    submission: "submission",
    decision: "decision",
    disqualification: "disqualification",
    no_contest: "no_contest",
    other: "other"
  }, prefix: :by, validate: true

  validates :ufcstats_id, presence: true, uniqueness: true
  validates :ending_round, numericality: { only_integer: true, in: 1..5 }, allow_nil: true
  validates :ending_time_seconds, numericality: { only_integer: true, in: 0..300 }, allow_nil: true
end
