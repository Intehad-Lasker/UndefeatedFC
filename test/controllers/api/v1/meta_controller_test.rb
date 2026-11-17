require "test_helper"

class Api::V1::MetaControllerTest < ActionDispatch::IntegrationTest
  test "lists the skill slots in order" do
    get "/api/v1/meta"

    assert_response :ok
    assert_equal Skills.keys, response.parsed_body["skills"].pluck("key")
    assert_equal "Striking", response.parsed_body["skills"].first["label"]
  end

  test "lists spinnable weight classes in display order" do
    get "/api/v1/meta"

    assert_equal %w[Lightweight Welterweight], response.parsed_body["weight_classes"].pluck("name")
  end

  test "lists eras chronologically with labels" do
    get "/api/v1/meta"

    assert_equal [ "Mainstream (2011-2015)", "Modern (2016-2020)", "Current (2021-present)" ],
      response.parsed_body["eras"].pluck("label")
  end

  test "describes the rules" do
    get "/api/v1/meta"

    assert_equal({ "rounds" => 6, "fights" => 15, "min_choices" => 8 }, response.parsed_body["rules"])
  end
end
