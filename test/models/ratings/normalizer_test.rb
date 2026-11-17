require "test_helper"

class Ratings::NormalizerTest < ActiveSupport::TestCase
  Entry = Ratings::Normalizer::Entry

  def normalize(*entries, **options) = Ratings::Normalizer.new(**options).call(entries)

  test "ranks the best raw score 99 and the worst 0" do
    ratings = normalize(Entry.new(:a, 1.0, 10), Entry.new(:b, 2.0, 10), Entry.new(:c, 3.0, 10))

    assert_equal({ a: 0, b: 50, c: 99 }, ratings)
  end

  test "ties share a rating" do
    ratings = normalize(Entry.new(:a, 1.0, 10), Entry.new(:b, 5.0, 10), Entry.new(:c, 5.0, 10))

    assert_equal ratings[:b], ratings[:c]
    assert_operator ratings[:b], :>, ratings[:a]
  end

  test "a small sample is pulled toward the average" do
    veteran = Entry.new(:veteran, 0.9, 20)
    one_hit_wonder = Entry.new(:one_hit_wonder, 1.0, 1)
    field = (1..8).map { |i| Entry.new(:"average_#{i}", 0.4, 10) }

    ratings = normalize(veteran, one_hit_wonder, *field)

    assert_operator ratings[:veteran], :>, ratings[:one_hit_wonder]
  end

  test "with no prior the raw order is kept exactly" do
    ratings = normalize(Entry.new(:veteran, 0.9, 20), Entry.new(:one_hit_wonder, 1.0, 1), prior_fights: 0)

    assert_operator ratings[:one_hit_wonder], :>, ratings[:veteran]
  end

  test "a fighter with no fights lands on the average" do
    ratings = normalize(Entry.new(:low, 1.0, 10), Entry.new(:high, 3.0, 10), Entry.new(:new, 99.0, 0))

    assert_equal 50, ratings[:new]
  end

  test "a lone fighter gets the middle rating" do
    assert_equal({ solo: 50 }, normalize(Entry.new(:solo, 7.0, 3)))
  end

  test "no entries gives no ratings" do
    assert_equal({}, normalize)
  end

  test "ratings always stay within 0 to 99" do
    random = Random.new(1)
    entries = Array.new(500) { |i| Entry.new(i, random.rand(-5.0..5.0), random.rand(0..30)) }

    assert normalize(*entries).values.all? { |value| FighterRating::RANGE.cover?(value) }
  end
end
