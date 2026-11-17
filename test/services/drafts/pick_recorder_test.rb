require "test_helper"

class Drafts::PickRecorderTest < ActiveSupport::TestCase
  # drafts(:fresh) has the striker in its striking slot and an open round at
  # Lightweight in the Mainstream era, whose pool is the striker and the grappler.

  def pick(fighter: fighters(:grappler), slot: "submissions", draft: drafts(:fresh))
    Drafts::PickRecorder.new(Draft.find(draft.id), fighter_id: fighter.id, slot: slot).call
  end

  test "fills the slot with the fighter and snapshots their rating" do
    round = pick

    assert_equal fighters(:grappler), round.fighter
    assert_equal "submissions", round.slot
    assert_equal 99, round.rating
    assert_not_nil round.picked_at
  end

  test "accepts the fighter id as a string, as it arrives from params" do
    round = Drafts::PickRecorder.new(Draft.find(drafts(:fresh).id), fighter_id: fighters(:grappler).id.to_s, slot: "chin").call

    assert_equal fighters(:grappler), round.fighter
  end

  test "an unrated fighter fills the slot with 0" do
    assert_equal 0, pick(slot: "chin").rating
  end

  test "rejects a fighter from a different pool" do
    error = assert_raises(Drafts::RuleViolation) { pick(fighter: fighters(:wrestler)) }

    assert_equal "That fighter did not fight at Lightweight in the Mainstream (2011-2015) era.", error.message
  end

  test "rejects a fighter already on the team" do
    assert_raises(Drafts::RuleViolation, match: "already drafted") { pick(fighter: fighters(:striker), slot: "power") }
  end

  test "rejects a slot that is already filled" do
    assert_raises(Drafts::RuleViolation, match: "Striking slot is already filled") { pick(slot: "striking") }
  end

  test "rejects a slot that does not exist" do
    assert_raises(Drafts::RuleViolation, match: '"cardio" is not a slot') { pick(slot: "cardio") }
  end

  test "rejects a pick before spinning" do
    assert_raises(Drafts::RuleViolation, match: "Spin before picking") { pick(draft: Draft.create!) }
  end

  test "rejects a pick on a finished draft" do
    assert_raises(Drafts::RuleViolation, match: "already finished") { pick(draft: drafts(:beaten)) }
  end

  test "a second pick in the same round is refused" do
    pick

    assert_raises(Drafts::RuleViolation, match: "Spin before picking") { pick(slot: "chin") }
  end
end
