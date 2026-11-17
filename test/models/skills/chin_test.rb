require "test_helper"

class Skills::ChinTest < ActiveSupport::TestCase
  include SkillContract

  def skill = Skills::Chin.new

  test "a fighter who has never been knocked out scores 1.0" do
    assert_in_delta 1.0, skill.raw_score(rated(:striker))
  end

  test "each knockout loss lowers the score" do
    # Grappler: knocked out once in two UFC fights.
    assert_in_delta 0.5, skill.raw_score(rated(:grappler))
  end
end
