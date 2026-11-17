require "test_helper"

class FighterSearchTest < ActiveSupport::TestCase
  test "finds a fighter by part of their name, ignoring case" do
    assert_equal [ fighters(:striker) ], Fighter.search("vance").to_a
  end

  test "finds a fighter despite a typo" do
    assert_equal fighters(:grappler), Fighter.search("Tomas Ferriera").first
  end

  test "finds a fighter by nickname" do
    assert_equal [ fighters(:striker) ], Fighter.search("metronome").to_a
  end

  test "ranks the closest name first" do
    Fighter.create!(ufcstats_id: "synthetic-kolter", name: "Dmitri Kolterman")

    assert_equal "Dmitri Kolt", Fighter.search("Dmitri Kolt").first.name
  end

  test "a blank query finds nobody" do
    assert_empty Fighter.search("   ")
  end

  test "SQL wildcards in the query are treated as text" do
    assert_empty Fighter.search("%")
  end

  test "the trigram index exists" do
    index = ActiveRecord::Base.connection.indexes(:fighters).find { |i| i.name == "index_fighters_on_name_trigram" }

    assert_equal :gin, index.using
  end
end
