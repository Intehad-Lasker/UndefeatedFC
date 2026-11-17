require "test_helper"

class DailyChallengeTest < ActiveSupport::TestCase
  test "for_day creates the challenge once and then returns it" do
    first = DailyChallenge.for_day(Date.new(2026, 12, 1))
    again = DailyChallenge.for_day(Date.new(2026, 12, 1))

    assert_equal first, again
    assert_includes Draft::SEED_RANGE, first.seed
  end

  test "an existing day keeps its seed" do
    assert_equal 1116, DailyChallenge.for_day(Date.new(2026, 11, 16)).seed
  end

  test "today uses the UTC date" do
    travel_to Time.utc(2026, 12, 2, 23, 30) do
      assert_equal Date.new(2026, 12, 2), DailyChallenge.today.day
    end
  end

  test "each day gets its own seed" do
    assert_not_equal DailyChallenge.for_day(Date.new(2026, 12, 3)).seed, DailyChallenge.for_day(Date.new(2026, 12, 4)).seed
  end

  test "the database allows one challenge per day" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      DailyChallenge.insert!({ day: Date.new(2026, 11, 16), seed: 5 })
    end
  end
end

class DailyChallengeDraftsTest < ActiveSupport::TestCase
  include DraftBuilder

  PLAYERS = %w[
    0d7d3a10-0000-4000-8000-000000000001
    0d7d3a10-0000-4000-8000-000000000002
  ].freeze

  setup do
    pools = %i[lightweight welterweight].product(%i[mainstream modern current])
    @sizes = pools.to_h { |wc, era| [ [ weight_classes(wc).id, eras(era).id ], 30 ] }
  end

  # Spins one round and fills it directly, returning the pool that came up.
  def spin_and_fill(draft, slot)
    round = Drafts::Spinner.new(Draft.find(draft.id), pool_sizes: -> { @sizes }).call
    fighter = Fighter.create!(ufcstats_id: "synthetic-dc-#{SecureRandom.hex(4)}", name: "Challenger")
    round.update!(fighter: fighter, slot: slot, rating: 70, picked_at: Time.current)
    [ round.weight_class_id, round.era_id ]
  end

  test "a challenge draft uses the challenge's seed" do
    challenge = daily_challenges(:yesterday)
    draft = challenge.start_draft!(player_id: PLAYERS.first)

    assert_equal challenge.seed, draft.seed
    assert draft.challenge?
  end

  test "every player gets the same spins in the same order" do
    challenge = daily_challenges(:yesterday)
    sequences = PLAYERS.map do |player_id|
      draft = challenge.start_draft!(player_id: player_id)
      Skills.keys.first(4).map { |slot| spin_and_fill(draft, slot) }
    end

    assert_equal sequences.first, sequences.last
  end

  test "ordinary drafts are not challenges" do
    assert_not Draft.create!.challenge?
  end
end

class DailyChallengeAttemptsTest < ActiveSupport::TestCase
  BROWSER_A = "0d7d3a10-0000-4000-8000-00000000000a".freeze
  BROWSER_B = "0d7d3a10-0000-4000-8000-00000000000b".freeze

  setup { @challenge = daily_challenges(:yesterday) }

  test "attempt! starts one attempt and then keeps returning it" do
    first = @challenge.attempt!(player_id: BROWSER_A)

    assert_equal first, @challenge.attempt!(player_id: BROWSER_A)
    assert_equal 1, @challenge.drafts.count
  end

  test "an account has one attempt across browsers" do
    first = @challenge.attempt!(player_id: BROWSER_A, user: users(:one))

    assert_equal first, @challenge.attempt!(player_id: BROWSER_B, user: users(:one))
  end

  test "a signed-in player picks up the attempt they started as a guest on this browser" do
    guest = @challenge.attempt!(player_id: BROWSER_A)

    assert_equal guest, @challenge.attempt!(player_id: BROWSER_A, user: users(:one))
  end

  test "different players get separate attempts" do
    assert_not_equal @challenge.attempt!(player_id: BROWSER_A), @challenge.attempt!(player_id: BROWSER_B)
  end

  test "the database refuses a second attempt from the same browser" do
    @challenge.start_draft!(player_id: BROWSER_A)

    assert_raises(ActiveRecord::RecordNotUnique) { @challenge.start_draft!(player_id: BROWSER_A) }
  end

  test "the database refuses a second attempt from the same account" do
    @challenge.start_draft!(player_id: BROWSER_A, user: users(:one))

    assert_raises(ActiveRecord::RecordNotUnique) { @challenge.start_draft!(player_id: BROWSER_B, user: users(:one)) }
  end

  test "ordinary drafts are not limited" do
    2.times { Draft.create!(player_id: BROWSER_A) }

    assert_equal 2, Draft.where(player_id: BROWSER_A, daily_challenge_id: nil).count
  end

  test "claiming skips a guest attempt at a challenge the account already played" do
    @challenge.start_draft!(player_id: BROWSER_B, user: users(:one))
    guest_attempt = @challenge.start_draft!(player_id: BROWSER_A)
    guest_casual = Draft.create!(player_id: BROWSER_A)

    Draft.claim_for(users(:one), player_id: BROWSER_A)

    assert_nil guest_attempt.reload.user_id
    assert_equal users(:one).id, guest_casual.reload.user_id
  end

  test "after signing out, the browser still sees the attempt it already used" do
    claimed = @challenge.attempt!(player_id: BROWSER_A, user: users(:one))

    assert_equal claimed, @challenge.attempt!(player_id: BROWSER_A)
    assert_equal 1, @challenge.drafts.count
  end
end
