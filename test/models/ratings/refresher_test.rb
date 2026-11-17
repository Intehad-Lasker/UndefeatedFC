require "test_helper"

class Ratings::RefresherTest < ActiveSupport::TestCase
  test "rates every fighter in every skill" do
    FighterRating.delete_all

    count = Ratings::Refresher.new.call

    assert_equal Fighter.count * Skills.all.size, count
    assert_equal count, FighterRating.count
  end

  test "each fixture fighter tops the skill they specialise in" do
    Ratings::Refresher.new(normalizer: Ratings::Normalizer.new(prior_fights: 0)).call

    { "striking" => :striker, "wrestling" => :wrestler, "submissions" => :grappler }.each do |skill, fixture|
      best = FighterRating.where(skill: skill).order(value: :desc).first

      assert_equal fighters(fixture).id, best.fighter_id, "expected #{fixture} to lead #{skill}"
    end
  end

  test "running twice updates ratings in place" do
    Ratings::Refresher.new.call

    assert_no_difference -> { FighterRating.count } do
      Ratings::Refresher.new.call
    end
  end

  test "overwrites stale values" do
    fighter_ratings(:striker_striking).update_column(:value, 1)

    Ratings::Refresher.new.call

    assert_operator fighter_ratings(:striker_striking).reload.value, :>, 1
  end

  test "removes ratings for skills that are no longer registered" do
    Ratings::Refresher.new(skills: [ Skills::Chin.new ]).call

    assert_equal [ "chin" ], FighterRating.distinct.pluck(:skill)
  end

  test "rates the whole roster in a fixed number of queries" do
    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name] == "SCHEMA" || payload[:sql].start_with?("SAVEPOINT", "RELEASE") }

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { Ratings::Refresher.new.call }

    assert_operator queries, :<=, 4
  end
end
