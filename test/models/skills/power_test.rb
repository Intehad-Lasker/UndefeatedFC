require "test_helper"

class Skills::PowerTest < ActiveSupport::TestCase
  include SkillContract

  def skill = Skills::Power.new

  test "ranks the knockout artist first" do
    assert_operator skill.raw_score(rated(:striker)), :>, skill.raw_score(rated(:grappler))
    assert_operator skill.raw_score(rated(:striker)), :>, skill.raw_score(rated(:wrestler))
  end

  test "combines knockout rate and knockdowns per fight" do
    # Striker: 1 of 1 wins by KO, 2 knockdowns over 3 fights.
    assert_in_delta 1.0 + (0.5 * 2 / 3.0), skill.raw_score(rated(:striker))
  end

  test "a fighter with no knockouts or knockdowns scores zero" do
    assert_in_delta 0.0, skill.raw_score(rated(:wrestler))
  end
end
