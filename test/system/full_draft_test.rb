require "application_system_test_case"

# Plays a whole solo draft in a real browser: React app, JSON API, CSRF cookie,
# seeded spins, picks, scoring and the results screen.
class FullDraftTest < ApplicationSystemTestCase
  include PoolBuilder

  setup do
    %i[lightweight welterweight].product(%i[mainstream modern current]).each do |wc, era|
      fill_pool(weight_class: weight_classes(wc), era: eras(era))
    end
    Ratings::Refresher.new.call
  end

  test "a player spins and picks six times and gets a title run" do
    visit "/"
    click_on "Start a draft"

    6.times do |index|
      assert_text "Round #{index + 1} of 6"
      click_on "Spin"
      within(find("ul[aria-label='Fighters in this pool']")) { first("button").click }
      first("button", text: /\APut .* here\z/).click
    end

    assert_selector "h1", text: "Title run complete"
    within(find("section[aria-label='Title run result']")) do
      assert_text(/\b\d{1,2}-\d{1,2}\b/)
      assert_selector "li", count: 15
    end
    draft = Draft.find(current_path.delete_prefix("/drafts/"))
    assert draft.completed?
    assert_equal 6, DraftRound.where(draft: draft).picked.count
  end
end
