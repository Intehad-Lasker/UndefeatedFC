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
