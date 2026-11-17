require "test_helper"

class Api::V1::HttpCachingTest < ActionDispatch::IntegrationTest
  include PoolBuilder

  def get_again(path)
    get path, headers: { "If-None-Match" => response.headers["ETag"] }
  end

  test "an unchanged draft answers 304" do
    get "/api/v1/drafts/#{drafts(:fresh).id}"
    get_again "/api/v1/drafts/#{drafts(:fresh).id}"

    assert_response :not_modified
    assert_empty response.body
  end

  test "a pick changes the draft's ETag" do
    fill_pool(weight_class: weight_classes(:welterweight), era: eras(:modern))
    post "/api/v1/drafts"
    id = response.parsed_body["id"]
    post "/api/v1/drafts/#{id}/rounds"
    get "/api/v1/drafts/#{id}"
    etag = response.headers["ETag"]
    fighter_id = response.parsed_body.dig("open_round", "pool", 0, "id")

    travel 1.second do
      post "/api/v1/drafts/#{id}/picks", params: { pick: { fighter_id: fighter_id, slot: "chin" } }, as: :json
      get "/api/v1/drafts/#{id}", headers: { "If-None-Match" => etag }
    end

    assert_response :ok
  end

  test "an unchanged fighter profile answers 304" do
    get "/api/v1/fighters/#{fighters(:striker).id}"
    get_again "/api/v1/fighters/#{fighters(:striker).id}"

    assert_response :not_modified
  end

  test "meta is publicly cacheable and answers 304 when unchanged" do
    get "/api/v1/meta"

    assert_includes response.headers["Cache-Control"], "public"

    get_again "/api/v1/meta"

    assert_response :not_modified
  end
end
