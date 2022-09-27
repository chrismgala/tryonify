# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ShopifyAppTemplateRuby
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults(7.0)

    config.assets.prefix = '/api/assets'

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.action_controller.asset_host = ENV.fetch('HOST', '').presence

    # Set ActiveJob adapter
    config.active_job.queue_adapter = :sidekiq

    # Camelcasing
    excluded_routes = ->(env) { !env['PATH_INFO'].match(%r{^/api}) }
    config.middleware.use OliveBranch::Middleware,
                          inflection: 'camel',
                          exclude_params: excluded_routes,
                          exclude_response: excluded_routes

    config.middleware.insert_before(0, Rack::Cors) do
      allow do
        origins '*' # Allow access to this api from any domain
        resource '*', # Allow all origins access to all resources
                 headers: %w[authorization content-type context], # Restrict headers to relevant keys
                 methods: %i[get post] # Restrict the methods to only the ones expected to be used by the extension
      end
    end
  end
end
