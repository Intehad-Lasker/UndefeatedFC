require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "signed-out visitors are sent to sign in" do
    get admin_root_path

    assert_redirected_to new_session_path
  end

  test "players who are not admins are refused" do
    sign_in_as users(:one)
    get admin_root_path

    assert_response :forbidden
    assert_select "h1", "Admins only"
  end

  test "admins see the dashboard" do
    sign_in_as users(:admin)
    get admin_root_path

    assert_response :ok
    assert_select ".admin__card-label", text: "Fighters"
    assert_select ".admin__card-value", text: Fighter.count.to_s
    assert_select "p", /Failed\s+.*ago/m # the newest fixture run failed
  end

  test "after signing in, an admin lands back on the dashboard" do
    get admin_root_path
    post session_path, params: { email_address: "admin@example.com", password: "password" }

    assert_redirected_to admin_root_url
  end
end
