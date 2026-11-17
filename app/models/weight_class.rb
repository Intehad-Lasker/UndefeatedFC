# A division such as Lightweight. Stored as a table rather than an enum so bouts
# reference it with a foreign key and admins can adjust which ones can be spun.
class WeightClass < ApplicationRecord
  has_many :bouts, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :position, presence: true, uniqueness: true, numericality: { only_integer: true }
  validates :limit_lbs, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :ordered, -> { order(:position) }
  scope :spinnable, -> { where(spinnable: true) }
end
