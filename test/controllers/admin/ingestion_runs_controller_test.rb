require "test_helper"

class Admin::IngestionRunsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup { sign_in_as users(:admin) }

  test "lists runs newest first with their errors" do
    get admin_ingestion_runs_path

    assert_response :ok
    rows = css_select("tbody tr")
    assert_equal 2, rows.size
    assert_match "HTTP 503 from ufcstats.com", rows.first.text
    assert_match "Succeeded", rows.last.text
  end

  test "the button queues a ratings refresh" do
    assert_enqueued_with(job: RatingsRefreshJob) do
      post refresh_ratings_admin_ingestion_runs_path
    end

    assert_redirected_to admin_ingestion_runs_path
    follow_redirect!
    assert_select ".admin__flash", /Ratings refresh queued/
  end

  test "non-admins cannot trigger a refresh" do
    sign_in_as users(:one)

    assert_no_enqueued_jobs { post refresh_ratings_admin_ingestion_runs_path }
    assert_response :forbidden
  end
end
