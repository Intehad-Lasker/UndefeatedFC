require "test_helper"
require "capybara/cuprite"

# End-to-end tests drive the real React build served by Rails (public/app), so
# build it first: cd web && npm run build.
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, screen_size: [ 1280, 900 ], options: {
    headless: true, process_timeout: 30, timeout: 15, js_errors: true,
    browser_options: { "no-sandbox" => nil } # needed in containers and CI
  }

  setup do
    Capybara.default_max_wait_time = 5
    assert File.exist?(Rails.public_path.join("app/index.html")), "Build the React app first: cd web && npm run build"
  end
end
