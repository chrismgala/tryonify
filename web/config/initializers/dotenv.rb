# frozen_string_literal: true

Dotenv.require_keys(
  # Shopify
  "APP_NAME",
  "SHOPIFY_API_KEY",
  "SHOPIFY_API_SECRET",
  "SCOPES",
  "HOST",
  "VITE_THEME_EXTENSION_ID", # Shopify theme extension ID for embedded app
  # Rails
  "RAILS_ENV",
  "RAILS_MASTER_KEY",
  "RAILS_LOG_TO_STDOUT",
  "RAILS_SERVE_STATIC_FILES",
  "RELEASE_ENV", # Describes to 3rd parties what environment it is
  # Sidekiq
  "SIDEKIQ_USERNAME",
  "SIDEKIQ_PASSWORD",
  # Slack
  "SLACK_CLIENT_ID",
  "SLACK_CLIENT_SECRET",
)
