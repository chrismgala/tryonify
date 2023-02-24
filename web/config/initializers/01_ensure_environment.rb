# frozen_string_literal: true

if Rails.env.development?
  [
    "APP_NAME",
    "SHOPIFY_API_KEY",
    "SHOPIFY_API_SECRET",
    "SCOPES",
    "HOST",
    "VITE_THEME_EXTENSION_ID",
    "RAILS_ENV",
    "RAILS_MASTER_KEY",
    "RAILS_LOG_TO_STDOUT",
    "RAILS_SERVE_STATIC_FILES",
    "RELEASE_ENV",
    "SIDEKIQ_USERNAME",
    "SIDEKIQ_PASSWORD",
    "SLACK_CLIENT_ID",
    "SLACK_CLIENT_SECRET",
  ].each do |env_var|
    next unless !ENV.has_key?(env_var) || ENV[env_var].blank?

    raise <<~EOL
      Missing environment variable: #{env_var}

      Ask a teammate for the appropriate value.
    EOL
  end
end
