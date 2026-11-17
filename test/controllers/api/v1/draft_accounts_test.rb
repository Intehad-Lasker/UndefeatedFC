require "test_helper"

class Api::V1::DraftAccountsTest < ActionDispatch::IntegrationTest
  def sign_in_with_password(user = users(:one))
    post "/api/v1/session", params: { email_address: user.email_address, password: "password" }, as: :json
  end

  test "a signed-in player's new draft belongs to their account" do
    sign_in_with_password
    post "/api/v1/drafts"

    assert_equal users(:one).id, Draft.find(response.parsed_body["id"]).user_id
  end

  test "signing in claims the drafts this browser played as a guest" do
    post "/api/v1/drafts"
    guest_draft = Draft.find(response.parsed_body["id"])

    sign_in_with_password

    assert_equal users(:one).id, guest_draft.reload.user_id
  end

  test "an account can keep playing its draft from another browser" do
    sign_in_with_password
    post "/api/v1/drafts"
    id = response.parsed_body["id"]

    reset!
    sign_in_with_password
    get "/api/v1/drafts/#{id}"

    assert response.parsed_body["owned"]
  end

  test "another account cannot change the draft" do
    sign_in_with_password(users(:one))
    post "/api/v1/drafts"
    id = response.parsed_body["id"]

    reset!
    sign_in_with_password(users(:two))
    post "/api/v1/drafts/#{id}/rounds"

    assert_response :forbidden
  end
end
