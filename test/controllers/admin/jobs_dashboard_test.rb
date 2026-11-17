require "test_helper"

# Mission Control reads Solid Queue's tables, which exist in production. Here
# jobs run in-process, so these tests cover how the dashboard is protected.
class Admin::JobsDashboardTest < ActionDispatch::IntegrationTest
  test "signed-out visitors are sent to sign in" do
    get "/admin/jobs"

    assert_redirected_to "/session/new"
  end

  test "non-admins are refused" do
    sign_in_as users(:one)
    get "/admin/jobs"

    assert_response :forbidden
  end

  test "the dashboard inherits the admin check instead of HTTP basic auth" do
    assert_operator MissionControl::Jobs::ApplicationController, :<, Admin::BaseController
    assert_not Rails.application.config.mission_control.jobs.http_basic_auth_enabled
  end

  test "the Jobs link only appears when Solid Queue runs the jobs" do
    sign_in_as users(:admin)
    get admin_root_path

    assert_select "a[href='/admin/jobs']", count: 0
  end
end
