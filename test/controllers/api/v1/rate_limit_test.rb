require "test_helper"

class Api::V1::RateLimitTest < ActionDispatch::IntegrationTest
  test "creating drafts too quickly is refused with a 429" do
    Api::V1::DraftsController::CREATE_LIMIT.times do
      post "/api/v1/drafts"
      assert_response :created
    end

    post "/api/v1/drafts"

    assert_response :too_many_requests
    assert_equal "rate_limited", response.parsed_body.dig("error", "code")
  end

  test "the limit resets after a minute" do
    (Api::V1::DraftsController::CREATE_LIMIT + 1).times { post "/api/v1/drafts" }

    travel 61.seconds do
      post "/api/v1/drafts"
    end

    assert_response :created
  end
end
