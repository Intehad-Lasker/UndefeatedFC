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

class DraftStateTest < ActiveSupport::TestCase
  def draft = Draft.with_rounds.find(drafts(:fresh).id)

  test "open_round is the spun but unpicked round" do
    assert_equal draft_rounds(:fresh_second), draft.open_round
  end

  test "tracks filled and open slots" do
    assert_equal [ "striking" ], draft.filled_slots
    assert_equal Skills.keys - [ "striking" ], draft.open_slots
    assert_not draft.all_slots_filled?
  end

  test "tracks drafted fighters and pools already spun" do
    assert_equal [ fighters(:striker).id ], draft.drafted_fighter_ids
    assert_equal [ [ weight_classes(:lightweight).id, eras(:modern).id ], [ weight_classes(:lightweight).id, eras(:mainstream).id ] ], draft.used_pools
  end

  test "next_round_number follows the last round" do
    assert_equal 3, draft.next_round_number
    assert_equal 1, Draft.with_rounds.find(Draft.create!.id).next_round_number
  end

  test "lock_with_rounds! reloads rounds without tripping strict loading" do
    record = Draft.find(drafts(:fresh).id)

    Draft.transaction do
      record.lock_with_rounds!

      assert_equal 2, record.rounds.size
      assert_equal eras(:mainstream), record.open_round.era
    end
  end

  test "reading rounds without loading them raises under strict loading" do
    assert_raises(ActiveRecord::StrictLoadingViolationError) { Draft.find(drafts(:fresh).id).open_round }
  end
end
