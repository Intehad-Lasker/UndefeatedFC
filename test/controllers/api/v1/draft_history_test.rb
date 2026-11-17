require "test_helper"

class Api::V1::DraftHistoryTest < ActionDispatch::IntegrationTest
  setup do
    drafts(:undefeated).update!(user: users(:one), created_at: 2.days.ago)
    drafts(:fresh).update!(user: users(:one), created_at: 1.day.ago)
    drafts(:beaten).update!(user: users(:two))
  end

  def sign_in_with_password(user = users(:one))
    post "/api/v1/session", params: { email_address: user.email_address, password: "password" }, as: :json
  end

  test "lists the player's drafts newest first with their results" do
    sign_in_with_password
    get "/api/v1/drafts"

    assert_response :ok
    drafts = response.parsed_body["drafts"]
    assert_equal [ drafts(:fresh).id, drafts(:undefeated).id ], drafts.pluck("id")
    assert_equal [ "in_progress", nil, 1 ], drafts.first.values_at("status", "record", "picks_made")
    assert_equal [ "15-0", true ], drafts.last.values_at("record", "undefeated")
  end

  test "never shows another player's drafts" do
    sign_in_with_password
    get "/api/v1/drafts"

    assert_not_includes response.parsed_body["drafts"].pluck("id"), drafts(:beaten).id
  end

  test "guests must sign in to see a history" do
    get "/api/v1/drafts"

    assert_response :unauthorized
    assert_equal "unauthorized", response.parsed_body.dig("error", "code")
  end
end
