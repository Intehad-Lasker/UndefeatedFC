require "test_helper"

class DraftRoundTest < ActiveSupport::TestCase
  def round(**attributes)
    DraftRound.new(draft: drafts(:beaten), number: 1, weight_class: weight_classes(:lightweight), era: eras(:modern), **attributes)
  end

  def pick(**attributes) = { fighter: fighters(:wrestler), slot: "wrestling", rating: 97, picked_at: Time.current, **attributes }

  test "an open round needs only a draft, number, weight class and era" do
    assert round.valid?
    assert_not round.picked?
  end

  test "a picked round needs its fighter, slot, rating and time" do
    assert round(**pick).valid?
    assert_not round(fighter: fighters(:wrestler)).valid?
  end

  test "rejects a slot that is not a skill" do
    assert_not round(**pick(slot: "cardio")).valid?
  end

  test "database allows only one open round per draft" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      DraftRound.create!(draft: drafts(:fresh), number: 3, weight_class: weight_classes(:welterweight), era: eras(:current))
    end
  end

  test "database rejects filling the same slot twice" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      draft_rounds(:fresh_second).update!(fighter: fighters(:wrestler), slot: "striking", rating: 10, picked_at: Time.current)
    end
  end

  test "database rejects drafting the same fighter twice" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      draft_rounds(:fresh_second).update!(fighter: fighters(:striker), slot: "power", rating: 10, picked_at: Time.current)
    end
  end

  test "database rejects a half-recorded pick" do
    assert_raises(ActiveRecord::StatementInvalid) do
      draft_rounds(:fresh_second).update_column(:fighter_id, fighters(:wrestler).id)
    end
  end

  test "a draft lists its rounds in order" do
    draft = Draft.includes(:rounds).find(drafts(:fresh).id)

    assert_equal [ 1, 2 ], draft.rounds.map(&:number)
  end

  test "open and picked scopes split the rounds" do
    assert_equal [ draft_rounds(:fresh_second) ], DraftRound.open.to_a
    assert_equal [ draft_rounds(:fresh_first) ], DraftRound.picked.to_a
  end
end
