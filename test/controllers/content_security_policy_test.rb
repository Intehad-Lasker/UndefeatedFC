require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  def policy = response.headers["Content-Security-Policy"].to_s

  test "the React app is served with a strict script policy" do
    SpaController.index_path = file_fixture("spa_index.html")
    get "/"

    assert_match(/script-src 'self' 'nonce-[^']+'/, policy)
    assert_match "object-src 'none'", policy
    assert_match "frame-ancestors 'none'", policy
    assert_match "connect-src 'self'", policy
  ensure
    SpaController.index_path = Rails.public_path.join("app/index.html")
  end

  test "admin pages put the request's nonce on the importmap script" do
    sign_in_as users(:admin)
    get admin_root_path

    nonce = policy[/'nonce-([^']+)'/, 1]
    assert nonce.present?
    assert_select "script[type='importmap'][nonce='#{nonce}']"
  end

  test "each request gets a different nonce" do
    sign_in_as users(:admin)
    nonces = Array.new(2) do
      get admin_root_path
      policy[/'nonce-([^']+)'/, 1]
    end

    assert_not_equal nonces.first, nonces.last
  end
end
