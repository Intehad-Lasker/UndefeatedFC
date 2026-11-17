require "test_helper"

class DailyChallengeTest < ActiveSupport::TestCase
  test "for_day creates the challenge once and then returns it" do
    first = DailyChallenge.for_day(Date.new(2026, 12, 1))
    again = DailyChallenge.for_day(Date.new(2026, 12, 1))

    assert_equal first, again
    assert_includes Draft::SEED_RANGE, first.seed
  end

  test "an existing day keeps its seed" do
    assert_equal 1116, DailyChallenge.for_day(Date.new(2026, 11, 16)).seed
  end

  test "today uses the UTC date" do
    travel_to Time.utc(2026, 12, 2, 23, 30) do
      assert_equal Date.new(2026, 12, 2), DailyChallenge.today.day
    end
  end

  test "each day gets its own seed" do
    assert_not_equal DailyChallenge.for_day(Date.new(2026, 12, 3)).seed, DailyChallenge.for_day(Date.new(2026, 12, 4)).seed
  end

  test "the database allows one challenge per day" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      DailyChallenge.insert!({ day: Date.new(2026, 11, 16), seed: 5 })
    end
  end
end
