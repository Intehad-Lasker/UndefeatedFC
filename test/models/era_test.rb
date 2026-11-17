require "test_helper"

class EraTest < ActiveSupport::TestCase
  test "is valid with a name and date range" do
    assert Era.new(name: "Pioneer", starts_on: Date.new(1993, 11, 12), ends_on: Date.new(2000, 12, 31)).valid?
  end

  test "requires the end date to be after the start date" do
    era = Era.new(name: "Backwards", starts_on: Date.new(1999, 1, 1), ends_on: Date.new(1998, 1, 1))

    assert_not era.valid?
    assert_includes era.errors[:ends_on], "must be after the start date"
  end

  test "rejects a range that overlaps an existing era" do
    era = Era.new(name: "Overlap", starts_on: Date.new(2015, 6, 1), ends_on: Date.new(2016, 6, 1))

    assert_not era.valid?
    assert_includes era.errors[:base], "overlaps another era"
  end

  test "database rejects overlapping eras even when validations are skipped" do
    assert_raises(ActiveRecord::StatementInvalid) do
      Era.insert!({ name: "Overlap", starts_on: Date.new(2018, 1, 1), ends_on: Date.new(2019, 1, 1) })
    end
  end

  test "an open-ended era overlaps anything after its start" do
    era = Era.new(name: "Future", starts_on: Date.new(2030, 1, 1))

    assert_not era.valid?
  end

  test "covers? includes both boundary dates" do
    era = eras(:modern)

    assert era.covers?(Date.new(2016, 1, 1))
    assert era.covers?(Date.new(2020, 12, 31))
    assert_not era.covers?(Date.new(2021, 1, 1))
  end

  test "covers? treats a missing end date as ongoing" do
    assert eras(:current).covers?(Date.new(2099, 1, 1))
  end

  test "label shows the year range" do
    assert_equal "Modern (2016-2020)", eras(:modern).label
    assert_equal "Current (2021-present)", eras(:current).label
  end

  test "ordered sorts chronologically" do
    assert_equal %w[Mainstream Modern Current], Era.ordered.pluck(:name)
  end
end
