require "test_helper"

class Skills::DefenseTest < ActiveSupport::TestCase
  include SkillContract

  def skill = Skills::Defense.new

  test "ranks the hard-to-hit wrestler first and the grappler last" do
    scores = %i[wrestler striker grappler].map { |name| skill.raw_score(rated(name)) }

    assert_equal scores.sort.reverse, scores
  end

  test "absorbing more strikes lowers the score" do
    fighter = rated(:wrestler)
    before = skill.raw_score(fighter)
    fighter.sig_strikes_absorbed_per_min += 2

    assert_in_delta before - 2, skill.raw_score(fighter)
  end
end
