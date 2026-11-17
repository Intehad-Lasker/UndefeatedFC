require "test_helper"

class Skills::WrestlingTest < ActiveSupport::TestCase
  include SkillContract

  def skill = Skills::Wrestling.new

  test "ranks the wrestler first and the striker last" do
    scores = %i[wrestler grappler striker].map { |name| skill.raw_score(rated(name)) }

    assert_equal scores.sort.reverse, scores
  end

  test "values takedown defense even without offense" do
    fighter = rated(:striker)
    fighter.takedowns_per_15_min = 0

    assert_in_delta 3 * 0.78, skill.raw_score(fighter)
  end
end
