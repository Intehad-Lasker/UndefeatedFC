require "test_helper"

class SkillsTest < ActiveSupport::TestCase
  class ReachAdvantage < Skills::Base; end

  test "every registered skill is a Skills::Base with a unique key" do
    assert Skills.all.all?(Skills::Base)
    assert_equal Skills.keys.uniq, Skills.keys
  end

  test "find returns a registered skill by string or symbol key" do
    assert_instance_of Skills::Striking, Skills.find("striking")
    assert_instance_of Skills::Striking, Skills.find(:striking)
  end

  test "find raises for an unknown key" do
    assert_raises(Skills::UnknownSkill) { Skills.find("telekinesis") }
  end

  test "key and label come from the class name" do
    skill = ReachAdvantage.new

    assert_equal "reach_advantage", skill.key
    assert_equal "Reach Advantage", skill.label
  end

  test "a skill that forgets to implement raw_score fails loudly" do
    assert_raises(NotImplementedError) { ReachAdvantage.new.raw_score(fighters(:striker)) }
    assert_raises(NotImplementedError) { ReachAdvantage.new.description }
  end
end
