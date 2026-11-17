require "test_helper"

class BoutTest < ActiveSupport::TestCase
  test "fixtures are valid" do
    assert bouts(:lightweight_2013).valid?
  end

  test "requires an event and a weight class" do
    bout = Bout.new(ufcstats_id: "new", finish: "decision")

    assert_not bout.valid?
    assert bout.errors.key?(:event)
    assert bout.errors.key?(:weight_class)
  end

  test "rejects an unknown finish with a validation error instead of raising" do
    bout = bouts(:lightweight_2013)
    bout.finish = "doctor_stoppage"

    assert_not bout.valid?
    assert bout.errors.key?(:finish)
  end

  test "database rejects an unknown finish even when validations are skipped" do
    assert_raises(ActiveRecord::StatementInvalid) do
      bouts(:lightweight_2013).update_column(:finish, "doctor_stoppage")
    end
  end

  test "rejects an ending round outside 1 to 5" do
    bout = bouts(:lightweight_2013)
    bout.ending_round = 6

    assert_not bout.valid?
  end

  test "finish scopes and predicates read naturally" do
    assert bouts(:lightweight_2013).by_ko_tko?
    assert_equal [ bouts(:welterweight_2023) ], Bout.by_submission.to_a
  end

  test "a weight class with bouts cannot be deleted" do
    weight_class = weight_classes(:lightweight)

    assert_not weight_class.destroy
    assert weight_class.errors.any?
  end
end
