require "test_helper"

class Admin::FightersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "lists fighters alphabetically" do
    get admin_fighters_path

    assert_response :ok
    assert_equal [ "Dmitri Kolt", "Rico Vance", "Tomas Ferreira" ], css_select("#fighters strong").map(&:text)
  end

  test "searches with the same typo-tolerant search as the game" do
    get admin_fighters_path(q: "ferriera")

    assert_equal [ "Tomas Ferreira" ], css_select("#fighters strong").map(&:text)
  end

  test "each row is a Turbo Frame and Edit loads the form into it" do
    fighter = fighters(:striker)
    get admin_fighters_path
    assert_select "turbo-frame#fighter_#{fighter.id}"

    get edit_admin_fighter_path(fighter)

    assert_select "turbo-frame#fighter_#{fighter.id} form input[name='fighter[nickname]'][value='The Metronome']"
  end

  test "saving returns the updated row" do
    fighter = fighters(:striker)

    patch admin_fighter_path(fighter), params: { fighter: { nickname: "Metronome", reach_cm: 190, locked: "1" } }

    assert_response :ok
    assert_select "turbo-frame#fighter_#{fighter.id}", /Metronome/
    fighter.reload
    assert_equal [ "Metronome", 190, true ], [ fighter.nickname, fighter.reach_cm, fighter.locked? ]
  end

  test "invalid edits re-render the form with errors" do
    patch admin_fighter_path(fighters(:striker)), params: { fighter: { name: "" } }

    assert_response :unprocessable_content
    assert_select ".admin__errors", /Name can't be blank/
  end

  test "stats are not editable here" do
    patch admin_fighter_path(fighters(:striker)), params: { fighter: { name: "Rico Vance", wins: 99 } }

    assert_equal 20, fighters(:striker).reload.wins
  end

  test "non-admins cannot edit" do
    sign_in_as users(:one)

    patch admin_fighter_path(fighters(:striker)), params: { fighter: { name: "Hacked" } }

    assert_response :forbidden
    assert_equal "Rico Vance", fighters(:striker).reload.name
  end
end
