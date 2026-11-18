require "test_helper"

class Pools::ChooserTest < ActiveSupport::TestCase
  SIZES = { [ 1, 10 ] => 30, [ 2, 10 ] => 25, [ 1, 11 ] => 5, [ 3, 12 ] => 20 }.freeze

  def chooser(min: 20) = Pools::Chooser.new(min_pool_size: min, pool_sizes: -> { SIZES })

  test "only pools at or above the minimum size qualify, sorted" do
    assert_equal [ [ 1, 10 ], [ 2, 10 ], [ 3, 12 ] ], chooser.eligible
  end

  test "used pools are excluded" do
    assert_equal [ [ 2, 10 ] ], chooser.eligible(used: [ [ 1, 10 ], [ 3, 12 ] ])
  end

  test "the same seed and round always choose the same pool" do
    picks = Array.new(5) { chooser.choose(seed: 99, round: 3) }

    assert_equal 1, picks.uniq.size
  end

  test "the choice does not depend on the order the database returns pools" do
    reversed = Pools::Chooser.new(min_pool_size: 20, pool_sizes: -> { SIZES.to_a.reverse.to_h })

    assert_equal chooser.choose(seed: 7, round: 1), reversed.choose(seed: 7, round: 1)
  end

  test "returns nil when nothing is left" do
    assert_nil chooser.choose(seed: 1, round: 1, used: chooser.eligible)
  end
end
