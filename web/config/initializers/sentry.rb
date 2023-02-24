# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = "https://65e428e6d02d4720b855e38ce3b9756d@o156936.ingest.sentry.io/6781816"
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.enabled_environments = ["production", "staging"]
  config.environment = ENV.fetch("RELEASE_ENV", "development")

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production.
  config.traces_sample_rate = 1.0
  # or
  config.traces_sampler = lambda do |_context|
    true
  end
end
