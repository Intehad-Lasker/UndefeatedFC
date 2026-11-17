require "test_helper"

class Api::V1::RoundsControllerTest < ActionDispatch::IntegrationTest
  include PoolBuilder

  setup do
    fill_pool(weight_class: weight_classes(:welterweight), era: eras(:modern))
    post "/api/v1/drafts"
    @draft_id = response.parsed_body["id"]
  end

  test "spinning opens a round on an eligible pool with its fighters" do
    post "/api/v1/drafts/#{@draft_id}/rounds"

    assert_response :created
    open_round = response.parsed_body["open_round"]
    assert_equal [ 1, "Welterweight", "Modern" ], [ open_round["number"], open_round.dig("weight_class", "name"), open_round.dig("era", "name") ]
    assert_equal Drafts::Spinner::MIN_POOL_SIZE, open_round["pool"].size
  end

  test "spinning twice without picking is a rule violation" do
    post "/api/v1/drafts/#{@draft_id}/rounds"
    post "/api/v1/drafts/#{@draft_id}/rounds"

    assert_response :unprocessable_content
    assert_equal "Pick a fighter before spinning again.", response.parsed_body.dig("error", "message")
  end

  test "another browser cannot spin someone else's draft" do
    post "/api/v1/drafts/#{drafts(:fresh).id}/rounds"

    assert_response :forbidden
    assert_equal "forbidden", response.parsed_body.dig("error", "code")
  end

  test "spinning an unknown draft is a 404" do
    post "/api/v1/drafts/#{SecureRandom.uuid}/rounds"

    assert_response :not_found
  end
end
