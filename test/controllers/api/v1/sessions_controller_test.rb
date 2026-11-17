require "test_helper"

class Api::V1::SessionsControllerTest < ActionDispatch::IntegrationTest
  def sign_in(password: "password")
    post "/api/v1/session", params: { email_address: users(:one).email_address, password: password }, as: :json
  end

  test "nobody is signed in at first" do
    get "/api/v1/session"

    assert_response :ok
    assert_nil response.parsed_body["user"]
  end

  test "signing in returns the user and keeps them signed in" do
    sign_in

    assert_response :created
    assert_equal "one@example.com", response.parsed_body.dig("user", "email_address")

    get "/api/v1/session"
    assert_equal users(:one).id, response.parsed_body.dig("user", "id")
  end

  test "email addresses are matched case-insensitively" do
    post "/api/v1/session", params: { email_address: " ONE@example.com ", password: "password" }, as: :json

    assert_response :created
  end

  test "a wrong password is a 401 with a clear message" do
    sign_in(password: "nope")

    assert_response :unauthorized
    assert_equal "invalid_credentials", response.parsed_body.dig("error", "code")
    assert_nil cookies[:session_id].presence
  end

  test "signing out ends the session" do
    sign_in
    delete "/api/v1/session"

    assert_response :no_content
    get "/api/v1/session"
    assert_nil response.parsed_body["user"]
  end

  test "repeated failed sign-ins are rate limited" do
    10.times { sign_in(password: "nope") }
    sign_in(password: "nope")

    assert_response :too_many_requests
  end
end
