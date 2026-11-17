require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "requires a unique UFCStats id, a name and a date" do
    event = Event.new(ufcstats_id: events(:numbered_2018).ufcstats_id)

    assert_not event.valid?
    assert event.errors.key?(:ufcstats_id)
    assert event.errors.key?(:name)
    assert event.errors.key?(:held_on)
  end

  test "during returns events inside an era, including its boundaries" do
    assert_equal [ events(:numbered_2018) ], Event.during(eras(:modern)).to_a
  end

  test "during an open-ended era includes everything after its start" do
    assert_equal [ events(:numbered_2023) ], Event.during(eras(:current)).to_a
  end

  test "chronological orders by date" do
    assert_equal events(:fight_night_2013, :numbered_2018, :numbered_2023), Event.chronological.to_a
  end
end
