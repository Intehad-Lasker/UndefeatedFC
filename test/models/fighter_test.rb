require "test_helper"

class FighterTest < ActiveSupport::TestCase
  test "fixtures are valid" do
    assert fighters(:striker).valid?
    assert fighters(:wrestler).valid?
  end

  test "requires a unique UFCStats id" do
    fighter = Fighter.new(ufcstats_id: fighters(:striker).ufcstats_id, name: "Copy")

    assert_not fighter.valid?
    assert_includes fighter.errors[:ufcstats_id], "has already been taken"
  end

  test "requires a name" do
    assert_not Fighter.new(ufcstats_id: "new").valid?
  end

  test "rejects percentages outside 0 to 1" do
    fighter = fighters(:striker)
    fighter.sig_strike_accuracy = 1.2

    assert_not fighter.valid?
  end

  test "rejects negative rates and record counts" do
    fighter = fighters(:striker)
    fighter.takedowns_per_15_min = -1
    fighter.losses = -1

    assert_not fighter.valid?
    assert fighter.errors.key?(:takedowns_per_15_min)
    assert fighter.errors.key?(:losses)
  end

  test "database rejects out-of-range percentages even when validations are skipped" do
    assert_raises(ActiveRecord::StatementInvalid) do
      fighters(:striker).update_column(:takedown_defense, 1.5)
    end
  end

  test "record formats wins, losses and draws" do
    assert_equal "20-3-0", fighters(:striker).record
  end

  test "record mentions no contests when there are any" do
    assert_equal "25-1-0 (1 NC)", fighters(:wrestler).record
  end
end
