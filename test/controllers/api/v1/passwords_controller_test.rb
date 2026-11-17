require "test_helper"

class Api::V1::PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "emails a reset link to a known address" do
    post "/api/v1/passwords", params: { email_address: " ONE@example.com " }, as: :json

    assert_response :accepted
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ users(:one) ]
  end

  test "answers the same way for an unknown address and sends nothing" do
    post "/api/v1/passwords", params: { email_address: "nobody@example.com" }, as: :json

    assert_response :accepted
    assert_enqueued_emails 0
    assert_match "If that address has an account", response.parsed_body["message"]
  end

  test "the email links to the reset page" do
    email = PasswordsMailer.reset(users(:one))

    assert_equal [ "one@example.com" ], email.to
    assert_match %r{http://example.com/passwords/[^/]+/edit}, email.text_part.body.to_s
  end

  test "an address is required" do
    post "/api/v1/passwords", params: {}, as: :json

    assert_response :bad_request
  end
end
