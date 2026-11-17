require "test_helper"

class FighterRatingTest < ActiveSupport::TestCase
  test "accepts a registered skill and a value from 0 to 99" do
    assert FighterRating.new(fighter: fighters(:grappler), skill: "power", value: 99).valid?
  end

  test "rejects a skill that is not registered" do
    rating = FighterRating.new(fighter: fighters(:grappler), skill: "telekinesis", value: 50)

    assert_not rating.valid?
    assert rating.errors.key?(:skill)
  end

  test "rejects values outside 0 to 99" do
    assert_not FighterRating.new(fighter: fighters(:grappler), skill: "chin", value: 100).valid?
    assert_not FighterRating.new(fighter: fighters(:grappler), skill: "chin", value: -1).valid?
  end

  test "database rejects out-of-range values" do
    assert_raises(ActiveRecord::StatementInvalid) do
      fighter_ratings(:striker_power).update_column(:value, 150)
    end
  end

  test "a fighter has one rating per skill" do
    duplicate = FighterRating.new(fighter: fighters(:striker), skill: "striking", value: 10)

    assert_not duplicate.valid?
  end

  test "rating_by_skill maps skill keys to values" do
    fighter = Fighter.includes(:ratings).find(fighters(:striker).id)

    assert_equal({ "striking" => 95, "power" => 88 }, fighter.rating_by_skill)
  end
end
