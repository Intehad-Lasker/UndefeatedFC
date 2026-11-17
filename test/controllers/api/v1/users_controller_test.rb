require "test_helper"

class Api::V1::UsersControllerTest < ActionDispatch::IntegrationTest
  def sign_up(**overrides)
    user = { email_address: "rookie@example.com", display_name: "Rookie", password: "correct horse battery" }.merge(overrides)
    post "/api/v1/users", params: { user: user }, as: :json
  end

  test "signing up creates the user and signs them in" do
    assert_difference -> { User.count } do
      sign_up
    end

    assert_response :created
    assert_equal "Rookie", response.parsed_body.dig("user", "display_name")
    get "/api/v1/session"
    assert_equal "rookie@example.com", response.parsed_body.dig("user", "email_address")
  end

  test "a taken display name is a 422 with field errors" do
    sign_up(display_name: "firstplayer")

    assert_response :unprocessable_content
    error = response.parsed_body["error"]
    assert_equal "validation_failed", error["code"]
    assert_equal [ "Display name has already been taken" ], error.dig("fields", "display_name")
  end

  test "a short password is refused" do
    sign_up(password: "short")

    assert_response :unprocessable_content
    assert error_fields = response.parsed_body.dig("error", "fields", "password")
    assert_match "too short", error_fields.first
  end

  test "an empty request is a 400" do
    post "/api/v1/users", params: {}, as: :json

    assert_response :bad_request
  end
end
