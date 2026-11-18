require "test_helper"

class MatchBroadcastJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper
  include MatchBuilder

  test "broadcasts a nudge on the match's stream" do
    match = Match.create!

    assert_broadcast_on("match:#{match.id}", { match_id: match.id }) { MatchBroadcastJob.perform_now(match.id) }
  end

  test "joining and picking each queue an update" do
    match = Matches::Creator.new(player_id: HOST, pool_sizes: -> { { [ 1, 1 ] => 50, [ 1, 2 ] => 50, [ 1, 3 ] => 50, [ 2, 1 ] => 50, [ 2, 2 ] => 50, [ 2, 3 ] => 50 } }).call

    assert_enqueued_with(job: MatchBroadcastJob, args: [ match.id ]) do
      Matches::Joiner.new(match, player_id: GUEST).call
    end

    built, roster = build_match
    assert_enqueued_with(job: MatchBroadcastJob, args: [ built.id ]) { pick(built, HOST, roster[0], "chin") }
  end

  test "a refused pick announces nothing" do
    built, roster = build_match

    assert_no_enqueued_jobs(only: MatchBroadcastJob) do
      assert_raises(Matches::RuleViolation) { pick(built, GUEST, roster[0], "chin") }
    end
  end
end
