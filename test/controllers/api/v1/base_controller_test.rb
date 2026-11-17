require "test_helper"

class Api::V1::BaseControllerTest < ActionDispatch::IntegrationTest
  class ProbeController < Api::V1::BaseController
    def not_found = Fighter.find(0)
    def missing_param = params.require(:draft)
    def rule = raise(Drafts::RuleViolation, "Spin before picking a fighter.")
    def forbidden = raise(Forbidden, "Only the player who started this draft can change it.")
    def player = render(json: { player_id: current_player_id })
    def write = render(json: { ok: true })
  end

  # Assertions must run inside the block: the integration session is reset
  # when with_routing finishes.
  def with_probe_routes
    with_routing do |set|
      set.draw do
        %w[not_found missing_param rule forbidden player].each do |action|
          get "probe/#{action}", controller: "api/v1/base_controller_test/probe", action: action
        end
        post "probe/write", controller: "api/v1/base_controller_test/probe", action: "write"
      end
      yield
    end
  end

  def error = response.parsed_body.fetch("error")

  test "missing records become a 404 with an error code and message" do
    with_probe_routes do
      get "/probe/not_found"

      assert_response :not_found
      assert_equal "not_found", error["code"]
    end
  end

  test "missing parameters become a 400" do
    with_probe_routes do
      get "/probe/missing_param"

      assert_response :bad_request
      assert_equal "bad_request", error["code"]
    end
  end

  test "rule violations become a 422 with the player-facing message" do
    with_probe_routes do
      get "/probe/rule"

      assert_response :unprocessable_content
      assert_equal({ "code" => "rule_violation", "message" => "Spin before picking a fighter." }, error)
    end
  end

  test "forbidden actions become a 403" do
    with_probe_routes do
      get "/probe/forbidden"

      assert_response :forbidden
      assert_equal "forbidden", error["code"]
    end
  end

  test "a browser keeps the same anonymous player id" do
    with_probe_routes do
      get "/probe/player"
      first = response.parsed_body["player_id"]
      get "/probe/player"

      assert_match(/\A\h{8}-/, first)
      assert_equal first, response.parsed_body["player_id"]
    end
  end

  test "every response carries a CSRF token" do
    with_probe_routes do
      get "/probe/player"

      assert response.headers["X-CSRF-Token"].present?
    end
  end

  test "writes without a valid CSRF token are refused" do
    with_forgery_protection do
      with_probe_routes do
        post "/probe/write"

        assert_response :forbidden
        assert_equal "invalid_csrf_token", error["code"]
      end
    end
  end

  test "writes that echo the CSRF token are accepted" do
    with_forgery_protection do
      with_probe_routes do
        get "/probe/player"
        post "/probe/write", headers: { "X-CSRF-Token" => response.headers["X-CSRF-Token"] }

        assert_response :ok
      end
    end
  end

  private

  def with_forgery_protection
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = original
  end
end
