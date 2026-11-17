require "test_helper"
require Rails.root.join("db/seeds/development_data")

class DevelopmentDataTest < ActiveSupport::TestCase
  setup do
    Seeds::ReferenceData.seed!
    Seeds::DevelopmentData.seed!(rng: Random.new(7), fighters_per_division: 12, years: 2014..2017)
  end

  def synthetic(scope) = scope.where("#{scope.table_name}.ufcstats_id LIKE 'synthetic-%'")

  test "creates fighters for every division active in those years" do
    divisions = Seeds::DevelopmentData::DIVISION_YEARS.count { |_, years| years.first <= 2017 && years.last >= 2014 }

    assert_equal divisions * 12, synthetic(Fighter).where.not(id: fighters(:striker, :wrestler, :grappler)).count
  end

  test "every synthetic bout has exactly one winner and one loser, or two draws" do
    outcomes = Appearance.joins(:bout).merge(synthetic(Bout)).group(:bout_id).pluck(Arel.sql("array_agg(outcome ORDER BY outcome)"))

    assert outcomes.any?
    assert outcomes.all? { |pair| pair == %w[loss win] || pair == %w[draw draw] }
  end

  test "generated stats satisfy the fighters table constraints" do
    assert synthetic(Fighter).all?(&:valid?)
  end

  test "records include every UFC result plus pre-UFC wins" do
    fighter = Fighter.with_ufc_record.merge(synthetic(Fighter)).find { |f| f.ufc_record.fights.positive? }

    assert_operator fighter.wins, :>=, fighter.ufc_record.wins + 3
    assert_operator fighter.losses, :>=, fighter.ufc_record.losses
  end

  test "the same seed produces the same fighters" do
    names = synthetic(Fighter).order(:ufcstats_id).pluck(:name)
    Appearance.joins(:fighter).merge(synthetic(Fighter)).delete_all
    synthetic(Bout).delete_all
    synthetic(Event).delete_all
    synthetic(Fighter).where.not(id: fighters(:striker, :wrestler, :grappler)).delete_all

    Seeds::DevelopmentData.seed!(rng: Random.new(7), fighters_per_division: 12, years: 2014..2017)

    assert_equal names, synthetic(Fighter).order(:ufcstats_id).pluck(:name)
  end
end
