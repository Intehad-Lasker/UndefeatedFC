require "test_helper"

class SpaControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original = SpaController.index_path
    SpaController.index_path = file_fixture("spa_index.html")
  end

  teardown { SpaController.index_path = @original }

  test "serves the React app at the root" do
    get "/"

    assert_response :ok
    assert_includes response.body, '<div id="root">'
    assert_equal "no-cache", response.headers["Cache-Control"]
  end

  test "serves the React app for client-side routes" do
    get "/drafts/#{drafts(:fresh).id}"

    assert_response :ok
    assert_includes response.body, '<div id="root">'
  end

  test "serves the app to clients that accept anything, like link previewers" do
    get "/drafts/#{drafts(:fresh).id}", headers: { "Accept" => "*/*" }

    assert_response :ok
  end

  test "a missing file is still a 404, not the app" do
    get "/missing.png"

    assert_response :not_found
  end

  test "leaves the API alone" do
    get "/api/v1/nope"

    assert_response :not_found
    assert_not_includes response.body, '<div id="root">'
  end

  test "explains how to build when the app is missing" do
    SpaController.index_path = Rails.root.join("tmp/missing.html")

    get "/"

    assert_response :service_unavailable
    assert_includes response.body, "npm run build"
  end
end
