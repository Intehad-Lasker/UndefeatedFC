require "test_helper"

class Skills::SubmissionsTest < ActiveSupport::TestCase
  include SkillContract

  def skill = Skills::Submissions.new

  test "ranks the grappler first" do
    assert_operator skill.raw_score(rated(:grappler)), :>, skill.raw_score(rated(:wrestler))
    assert_operator skill.raw_score(rated(:wrestler)), :>, skill.raw_score(rated(:striker))
  end

  test "counts submission finishes on top of attempts" do
    # Grappler: 2.4 attempts per 15 minutes, 1 of 1 UFC wins by submission.
    assert_in_delta 2.4 + 3, skill.raw_score(rated(:grappler))
  end
end
