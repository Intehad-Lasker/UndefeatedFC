require "test_helper"

class Matches::CreatorAndJoinerTest < ActiveSupport::TestCase
  HOST = "22222222-0000-4000-8000-000000000001".freeze
  GUEST = "22222222-0000-4000-8000-000000000002".freeze
  LATE = "22222222-0000-4000-8000-000000000003".freeze

  def pool_sizes(count: 6)
    pools = %i[lightweight welterweight].product(%i[mainstream modern current]).first(count)
    -> { pools.to_h { |wc, era| [ [ weight_classes(wc).id, eras(era).id ], 40 ] } }
  end

  def create_match(user: nil, **options)
    Matches::Creator.new(player_id: HOST, user: user, pool_sizes: pool_sizes(**options)).call
  end

  test "creating a match seats the host and fixes six distinct pools" do
    match = create_match(user: users(:one))

    assert match.waiting?
    assert_equal 6, match.pools.uniq.size
    host = match.players.sole
    assert_equal [ 1, "FirstPlayer" ], [ host.seat, host.display_name ]
  end

  test "guests get a generic name" do
    assert_equal "Player 1", create_match.players.sole.display_name
  end

  test "a match needs enough qualifying pools" do
    error = assert_raises(Matches::RuleViolation) { create_match(count: 5) }

    assert_match "isn't enough fighter data", error.message
  end

  test "the same seed always produces the same pools" do
    first = Match.new(seed: 5)
    chooser = Pools::Chooser.new(min_pool_size: 1, pool_sizes: pool_sizes)
    a = (1..6).each_with_object([]) { |r, used| used << chooser.choose(seed: first.seed, round: r, used: used) }
    b = (1..6).each_with_object([]) { |r, used| used << chooser.choose(seed: first.seed, round: r, used: used) }

    assert_equal a, b
  end

  test "joining takes seat 2 and starts the draft" do
    match = create_match

    player = Matches::Joiner.new(match, player_id: GUEST, user: users(:two)).call

    assert_equal [ 2, "SecondPlayer" ], [ player.seat, player.display_name ]
    assert match.reload.drafting?
  end

  test "opening your own invite link again returns your seat" do
    match = create_match

    assert_equal 1, Matches::Joiner.new(match, player_id: HOST).call.seat
    assert match.reload.waiting?
  end

  test "a full match turns away a third player" do
    match = create_match
    Matches::Joiner.new(match, player_id: GUEST).call

    assert_raises(Matches::RuleViolation, match: "already has two players") do
      Matches::Joiner.new(match.reload, player_id: LATE).call
    end
  end

  test "match rule violations are draft rule violations, so the API handles them" do
    assert_operator Matches::RuleViolation, :<, Drafts::RuleViolation
  end
end
