require "test_helper"

class Api::V1::PicksControllerTest < ActionDispatch::IntegrationTest
  include PoolBuilder

  setup do
    %i[lightweight welterweight].product(%i[mainstream modern current]).each do |weight_class, era|
      fill_pool(weight_class: weight_classes(weight_class), era: eras(era))
    end
    post "/api/v1/drafts"
    @draft_id = response.parsed_body["id"]
  end

  def spin
    post "/api/v1/drafts/#{@draft_id}/rounds"
    response.parsed_body
  end

  def pick(fighter_id:, slot:)
    post "/api/v1/drafts/#{@draft_id}/picks", params: { pick: { fighter_id: fighter_id, slot: slot } }, as: :json
    response.parsed_body
  end

  test "a pick fills the slot and reveals the rating" do
    fighter = spin.dig("open_round", "pool").first

    body = pick(fighter_id: fighter["id"], slot: "power")

    assert_response :created
    slot = body["slots"].find { |s| s["key"] == "power" }
    assert_equal fighter["id"], slot.dig("fighter", "id")
    assert_kind_of Integer, slot["rating"]
    assert_nil body["open_round"]
  end

  test "six spins and six picks finish the draft with a title run" do
    Skills.keys.each do |slot|
      fighter = spin.dig("open_round", "pool").first
      pick(fighter_id: fighter["id"], slot: slot)
    end

    assert_response :created
    result = response.parsed_body["result"]
    assert_equal "completed", response.parsed_body["status"]
    assert_equal 15, result["fights"].size
    assert_equal 15, result["wins"] + result["losses"]
  end

  test "picking a fighter from outside the pool is a rule violation" do
    spin
    outsider = Fighter.create!(ufcstats_id: "synthetic-outsider", name: "Never Fought")

    pick(fighter_id: outsider.id, slot: "power")

    assert_response :unprocessable_content
    assert_match "did not fight at", response.parsed_body.dig("error", "message")
  end

  test "a pick without a slot is a bad request" do
    spin

    post "/api/v1/drafts/#{@draft_id}/picks", params: { pick: { fighter_id: 1 } }, as: :json

    assert_response :bad_request
  end

  test "another browser cannot pick in someone else's draft" do
    post "/api/v1/drafts/#{drafts(:fresh).id}/picks", params: { pick: { fighter_id: fighters(:grappler).id, slot: "chin" } }, as: :json

    assert_response :forbidden
  end
end
