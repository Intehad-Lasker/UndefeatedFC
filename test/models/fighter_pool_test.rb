require "test_helper"

class FighterPoolTest < ActiveSupport::TestCase
  test "in_pool returns everyone who fought in that weight class during that era" do
    pool = Fighter.in_pool(weight_class: weight_classes(:lightweight), era: eras(:modern))

    assert_equal fighters(:striker, :wrestler).map(&:id).sort, pool.ids.sort
  end

  test "in_pool respects era boundaries" do
    pool = Fighter.in_pool(weight_class: weight_classes(:lightweight), era: eras(:mainstream))

    assert_equal fighters(:grappler, :striker).map(&:id).sort, pool.ids.sort
  end

  test "in_pool works with an open-ended era" do
    pool = Fighter.in_pool(weight_class: weight_classes(:welterweight), era: eras(:current))

    assert_equal fighters(:grappler, :striker).map(&:id).sort, pool.ids.sort
  end

  test "in_pool is empty when nobody fought there" do
    assert_empty Fighter.in_pool(weight_class: weight_classes(:welterweight), era: eras(:modern))
  end

  test "in_pool lists a fighter once however many times they fought there" do
    Bout.create!(ufcstats_id: "synthetic-rematch", event: events(:numbered_2018), weight_class: weight_classes(:lightweight), finish: "decision")
      .appearances.create!(fighter: fighters(:striker), outcome: "win")

    pool = Fighter.in_pool(weight_class: weight_classes(:lightweight), era: eras(:modern))

    assert_equal 2, pool.count
  end

  test "in_pool composes with other scopes" do
    pool = Fighter.in_pool(weight_class: weight_classes(:lightweight), era: eras(:modern)).with_ufc_record

    assert_equal 2, pool.to_a.size
  end

  test "pool_sizes counts distinct fighters for every spinnable pool in one query" do
    sizes = Fighter.pool_sizes

    assert_equal 2, sizes[[ weight_classes(:lightweight).id, eras(:mainstream).id ]]
    assert_equal 2, sizes[[ weight_classes(:lightweight).id, eras(:modern).id ]]
    assert_equal 2, sizes[[ weight_classes(:welterweight).id, eras(:current).id ]]
    assert_equal 3, sizes.size
  end

  test "pool_sizes skips weight classes that cannot be spun" do
    bout = Bout.create!(ufcstats_id: "synthetic-catchweight", event: events(:numbered_2018), weight_class: weight_classes(:catch_weight), finish: "decision")
    bout.appearances.create!(fighter: fighters(:wrestler), outcome: "win")

    assert_not Fighter.pool_sizes.keys.map(&:first).include?(weight_classes(:catch_weight).id)
  end
end
