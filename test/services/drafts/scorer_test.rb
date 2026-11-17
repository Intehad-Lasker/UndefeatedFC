require "test_helper"

class Drafts::ScorerTest < ActiveSupport::TestCase
  include DraftBuilder
  include ActiveJob::TestHelper

  test "averages the six slot ratings into the overall" do
    draft = build_draft(ratings: [ 90, 80, 70, 60, 50, 40 ])

    Drafts::Scorer.new(draft).call

    assert_equal 65, draft.reload.overall
  end

  test "completes the draft with its record and fight log" do
    draft = build_draft(ratings: [ 85 ] * 6)

    result = Drafts::Scorer.new(draft).call
    draft.reload

    assert draft.completed?
    assert_equal [ result.wins, result.losses ], [ draft.wins, draft.losses ]
    assert_equal 15, draft.fight_log.size
    assert_equal %w[number opponent_rating win_probability won], draft.fight_log.first.keys.sort # jsonb does not keep key order
    assert_not_nil draft.completed_at
  end

  test "the same seed and picks always give the same record" do
    records = Array.new(2) do
      draft = build_draft(ratings: [ 75 ] * 6, seed: 2026)
      Drafts::Scorer.new(draft).call
      draft.reload.record
    end

    assert_equal 1, records.uniq.size
  end

  test "queues a leaderboard broadcast for the finished draft" do
    draft = build_draft(ratings: [ 80 ] * 6)

    assert_enqueued_with(job: LeaderboardBroadcastJob, args: [ draft.id ]) do
      Drafts::Scorer.new(draft).call
    end
  end

  test "nothing is broadcast if the transaction rolls back" do
    draft = build_draft(ratings: [ 80 ] * 6)

    assert_no_enqueued_jobs(only: LeaderboardBroadcastJob) do
      Draft.transaction do
        Drafts::Scorer.new(draft).call
        raise ActiveRecord::Rollback
      end
    end
  end

  test "refuses to score a draft with an empty slot" do
    draft = build_draft(ratings: [ 90 ] * 5)

    assert_raises(Drafts::RuleViolation, match: "Fill every slot") { Drafts::Scorer.new(draft).call }
  end

  test "uses an injected simulator" do
    always_win = Struct.new(:overall) do
      def call(overall) = FightSimulator::Result.new(fights: Array.new(15) { |i| FightSimulator::Fight.new(i + 1, 60, 0.9, true) })
    end.new

    draft = build_draft(ratings: [ 10 ] * 6)
    Drafts::Scorer.new(draft, simulator: always_win).call

    assert draft.reload.undefeated?
  end
end

class Drafts::PickRecorderScoringTest < ActiveSupport::TestCase
  include DraftBuilder

  test "the pick that fills the last slot finishes the draft" do
    draft = build_draft(ratings: [ 80 ] * 5, open_round: true)
    candidate = fighters(:wrestler)

    Drafts::PickRecorder.new(Draft.find(draft.id), fighter_id: candidate.id, slot: Skills.keys.last).call

    assert draft.reload.completed?
    assert_equal 15, draft.wins + draft.losses
  end

  test "earlier picks leave the draft in progress" do
    draft = build_draft(ratings: [ 80 ] * 4, open_round: true)

    Drafts::PickRecorder.new(Draft.find(draft.id), fighter_id: fighters(:wrestler).id, slot: Skills.keys.fifth).call

    assert draft.reload.in_progress?
  end
end
