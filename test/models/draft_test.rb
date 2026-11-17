require "test_helper"

class DraftTest < ActiveSupport::TestCase
  test "gets a UUID id and a random seed" do
    draft = Draft.create!

    assert_match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/, draft.id)
    assert_includes Draft::SEED_RANGE, draft.seed
    assert draft.in_progress?
  end

  test "two drafts get different seeds" do
    assert_not_equal Draft.create!.seed, Draft.create!.seed
  end

  test "a completed draft must have its result" do
    draft = drafts(:fresh)
    draft.status = "completed"

    assert_not draft.valid?
    assert draft.errors.key?(:overall)
    assert draft.errors.key?(:completed_at)
  end

  test "database rejects a completed draft without a result" do
    assert_raises(ActiveRecord::StatementInvalid) do
      drafts(:fresh).update_column(:status, "completed")
    end
  end

  test "rejects an overall rating outside 0 to 99" do
    draft = drafts(:beaten)
    draft.overall = 100

    assert_not draft.valid?
  end

  test "record and undefeated? describe the result" do
    assert_equal "15-0", drafts(:undefeated).record
    assert drafts(:undefeated).undefeated?
    assert_not drafts(:beaten).undefeated?
    assert_nil drafts(:fresh).record
  end

  test "fight_log defaults to an empty list" do
    assert_equal [], Draft.create!.fight_log
  end
end
