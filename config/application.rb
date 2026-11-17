require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module UndefeatedFc
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Lazy-loading an association must be explicit (includes/preload). This turns
    # N+1 queries into errors in development and test instead of slow pages later.
    config.active_record.strict_loading_by_default = true

    # The jobs dashboard sits behind the same sign-in and admin check as the rest
    # of /admin, instead of the gem's default HTTP basic auth.
    config.mission_control.jobs.base_controller_class = "Admin::BaseController"
    config.mission_control.jobs.http_basic_auth_enabled = false

    config.generators do |g|
      g.helper false
      g.system_tests nil
    end
  end
end
