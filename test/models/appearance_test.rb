require "test_helper"

class AppearanceTest < ActiveSupport::TestCase
  test "a fighter appears in a bout only once" do
    duplicate = Appearance.new(bout: bouts(:lightweight_2013), fighter: fighters(:striker), outcome: "win")

    assert_not duplicate.valid?
    assert duplicate.errors.key?(:fighter_id)
  end

  test "database rejects a duplicate fighter in the same bout" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      Appearance.insert!({ bout_id: bouts(:lightweight_2013).id, fighter_id: fighters(:striker).id, outcome: "win" })
    end
  end

  test "a bout holds at most two fighters" do
    third = Appearance.new(bout: bouts(:lightweight_2013), fighter: fighters(:wrestler), outcome: "draw")

    assert_not third.valid?
    assert_includes third.errors[:bout], "already has 2 fighters"
  end

  test "rejects an unknown outcome" do
    appearance = appearances(:striker_2013)
    appearance.outcome = "forfeit"

    assert_not appearance.valid?
  end

  test "rejects negative counts" do
    appearance = appearances(:striker_2013)
    appearance.knockdowns = -1

    assert_not appearance.valid?
  end

  test "bouts and fighters connect through appearances" do
    bout = Bout.includes(:fighters).find(bouts(:lightweight_2013).id)

    assert_equal fighters(:grappler, :striker).map(&:name).sort, bout.fighters.map(&:name).sort
  end

  test "lazy loading appearances off a collection raises under strict loading" do
    fighter = Fighter.where(id: fighters(:striker).id).first

    assert_raises(ActiveRecord::StrictLoadingViolationError) { fighter.appearances.to_a }
  end
end
