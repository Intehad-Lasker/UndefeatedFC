require "test_helper"

class Drafts::SpinnerTest < ActiveSupport::TestCase
  setup do
    @lightweight_modern = [ weight_classes(:lightweight).id, eras(:modern).id ]
    @lightweight_mainstream = [ weight_classes(:lightweight).id, eras(:mainstream).id ]
    @welterweight_current = [ weight_classes(:welterweight).id, eras(:current).id ]
    @sizes = { @lightweight_modern => 30, @lightweight_mainstream => 20, @welterweight_current => 25 }
  end

  def spin(draft, sizes: @sizes, **options)
    Drafts::Spinner.new(draft, pool_sizes: -> { sizes }, **options).call
  end

  test "creates the first round on an eligible pool" do
    round = spin(Draft.create!)

    assert_equal 1, round.number
    assert_includes @sizes.keys, [ round.weight_class_id, round.era_id ]
    assert_not round.picked?
  end

  test "the same seed always spins the same pools in the same order" do
    first, second = Array.new(2) do
      draft = Draft.create!(seed: 1234)
      Array.new(3) { spin_and_fake_pick(draft) }
    end

    assert_equal first, second
  end

  test "different seeds usually spin a different order" do
    orders = (1..6).map do |seed|
      draft = Draft.create!(seed: seed)
      Array.new(3) { spin_and_fake_pick(draft) }
    end

    assert_operator orders.uniq.size, :>, 1
  end

  test "skips pools too small to leave enough choices" do
    sizes = { @lightweight_modern => Drafts::Spinner::MIN_POOL_SIZE - 1, @welterweight_current => Drafts::Spinner::MIN_POOL_SIZE }

    round = spin(Draft.create!, sizes: sizes)

    assert_equal @welterweight_current, [ round.weight_class_id, round.era_id ]
  end

  test "never repeats a pool within a draft" do
    draft = Draft.create!
    pools = Array.new(3) { spin_and_fake_pick(draft) }

    assert_equal pools.uniq, pools
    assert_raises(Drafts::RuleViolation, match: /no pools left/) { spin(draft) }
  end

  test "refuses to spin while a round is waiting for a pick" do
    error = assert_raises(Drafts::RuleViolation) { spin(drafts(:fresh)) }

    assert_equal "Pick a fighter before spinning again.", error.message
  end

  test "refuses to spin a finished draft" do
    assert_raises(Drafts::RuleViolation, match: /already finished/) { spin(drafts(:beaten)) }
  end

  test "uses an injected random number generator" do
    picks = Array.new(5) { spin(Draft.create!, rng: Random.new(1)).then { |round| [ round.weight_class_id, round.era_id ] } }

    assert_equal 1, picks.uniq.size
  end

  test "with real data, pools smaller than the minimum are never offered" do
    assert_raises(Drafts::RuleViolation, match: /no pools left/) do
      Drafts::Spinner.new(Draft.create!).call
    end
  end

  private

  # Spins, then fills the round directly so the next spin is allowed.
  def spin_and_fake_pick(draft)
    round = spin(Draft.find(draft.id))
    slot = (Skills.keys - DraftRound.where(draft: draft).pluck(:slot)).first
    fighter = Fighter.create!(ufcstats_id: "synthetic-spin-#{SecureRandom.hex(4)}", name: "Pick")
    round.update!(fighter: fighter, slot: slot, rating: 50, picked_at: Time.current)
    [ round.weight_class_id, round.era_id ]
  end
end
