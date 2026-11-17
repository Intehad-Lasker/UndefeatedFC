require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "seeds every weight class and era" do
    Rails.application.load_seed

    assert_equal Seeds::ReferenceData::WEIGHT_CLASSES.size, WeightClass.count
    assert_equal Seeds::ReferenceData::ERAS.size, Era.count
  end

  test "running the seeds twice does not duplicate rows" do
    2.times { Rails.application.load_seed }

    assert_equal Seeds::ReferenceData::WEIGHT_CLASSES.size, WeightClass.count
    assert_equal Seeds::ReferenceData::ERAS.size, Era.count
  end

  test "catch weight is the only division that cannot be spun" do
    Rails.application.load_seed

    assert_equal [ "Catch Weight" ], WeightClass.where(spinnable: false).pluck(:name)
  end

  test "eras run back to back with only the current era left open" do
    Rails.application.load_seed

    eras = Era.ordered.to_a
    eras.each_cons(2) { |earlier, later| assert_equal earlier.ends_on + 1, later.starts_on }
    assert_nil eras.last.ends_on
  end
end
