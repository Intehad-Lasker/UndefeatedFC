# Shared tests every skill must pass, so any skill can stand in for another
# (the Liskov substitution principle). Include it and define #skill.
module SkillContract
  def self.included(base)
    base.class_eval do
      test "has a snake_case key and a label" do
        assert_match(/\A[a-z]+(_[a-z]+)*\z/, skill.key)
        assert skill.label.present?
      end

      test "describes what it measures" do
        assert skill.description.present?
      end

      test "scores an experienced fighter with a finite number" do
        assert_finite_score skill.raw_score(rated(:striker))
      end

      test "scores a fighter with no UFC fights and zeroed stats" do
        newcomer = Fighter.create!(ufcstats_id: "synthetic-contract-newcomer", name: "New Comer")

        assert_finite_score skill.raw_score(Fighter.with_ufc_record.find(newcomer.id))
      end
    end
  end

  private

  def rated(fixture) = Fighter.with_ufc_record.find(fighters(fixture).id)

  def assert_finite_score(score)
    assert_kind_of Numeric, score
    assert score.to_f.finite?, "expected a finite score, got #{score.inspect}"
  end
end
