require "test_helper"

class WeightClassTest < ActiveSupport::TestCase
  test "is valid with a name and position" do
    assert WeightClass.new(name: "Flyweight", position: 1, limit_lbs: 125).valid?
  end

  test "requires a unique name" do
    duplicate = WeightClass.new(name: weight_classes(:lightweight).name, position: 99)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "requires a unique position" do
    duplicate = WeightClass.new(name: "Flyweight", position: weight_classes(:lightweight).position)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:position], "has already been taken"
  end

  test "allows no weight limit for open and catch weight bouts" do
    assert weight_classes(:catch_weight).valid?
  end

  test "rejects a non-positive weight limit" do
    weight_class = weight_classes(:lightweight)
    weight_class.limit_lbs = 0

    assert_not weight_class.valid?
  end

  test "database rejects a non-positive weight limit even when validations are skipped" do
    assert_raises(ActiveRecord::StatementInvalid) do
      weight_classes(:lightweight).update_column(:limit_lbs, -1)
    end
  end

  test "ordered sorts by position" do
    assert_equal %w[Lightweight Welterweight Catch\ Weight], WeightClass.ordered.pluck(:name)
  end

  test "spinnable excludes divisions that cannot be spun" do
    assert_not_includes WeightClass.spinnable, weight_classes(:catch_weight)
  end
end
