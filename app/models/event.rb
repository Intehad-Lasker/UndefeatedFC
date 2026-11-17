# A UFC card, such as "UFC 300". Its date decides which era its bouts belong to.
class Event < ApplicationRecord
  validates :ufcstats_id, presence: true, uniqueness: true
  validates :name, :held_on, presence: true

  scope :chronological, -> { order(:held_on) }
  scope :during, ->(era) { where(held_on: era.starts_on..era.ends_on) }
end
