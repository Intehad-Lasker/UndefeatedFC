require "test_helper"

class Skills::StrikingTest < ActiveSupport::TestCase
  include SkillContract

  def skill = Skills::Striking.new

  test "ranks the volume striker above the wrestler and the grappler" do
    scores = %i[striker wrestler grappler].map { |name| skill.raw_score(rated(name)) }

    assert_equal scores.sort.reverse, scores
  end

  test "rewards accuracy at the same output" do
    fighter = rated(:striker)
    accurate = skill.raw_score(fighter)
    fighter.sig_strike_accuracy = 0.30

    assert_operator accurate, :>, skill.raw_score(fighter)
  end
end
