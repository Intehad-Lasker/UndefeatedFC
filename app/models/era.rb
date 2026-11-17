# A span of UFC history, such as 2012-2016. The current era has no end date.
class Era < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :starts_on, presence: true
  validate :ends_after_start
  validate :does_not_overlap_another_era

  scope :ordered, -> { order(:starts_on) }

  def covers?(date)
    date >= starts_on && (ends_on.nil? || date <= ends_on)
  end

  def label
    "#{name} (#{starts_on.year}-#{ends_on&.year || 'present'})"
  end

  private

  def ends_after_start
    return if starts_on.blank? || ends_on.blank? || starts_on < ends_on

    errors.add(:ends_on, "must be after the start date")
  end

  def does_not_overlap_another_era
    return if starts_on.blank? || errors.include?(:ends_on)

    overlapping = Era.where.not(id: id)
      .where("daterange(starts_on, ends_on, '[]') && daterange(?, ?, '[]')", starts_on, ends_on)
    errors.add(:base, "overlaps another era") if overlapping.exists?
  end
end
