# frozen_string_literal: true

ShopifyApp.configure do |config|
  config.webhooks = [
    # After a store owner uninstalls your app, Shopify invokes the APP_UNINSTALLED webhook
    # to let your app know.
    { topic: 'app/uninstalled', path: 'api/webhooks/app_uninstalled' },
    { topic: 'orders/create', path: 'api/webhooks/orders_create' },
    { topic: 'orders/updated', path: 'api/webhooks/orders_updated' },
    { topic: 'orders/edited', path: 'api/webhooks/orders_edited' },
    { topic: 'shop/update', path: 'api/webhooks/shop_update' }
  ]
  config.application_name = 'TryOnify'
  config.old_secret = ''
  config.scope = ENV.fetch('SCOPES', 'write_products') # See shopify.app.toml for scopes
  # Consult this page for more scope options: https://shopify.dev/api/usage/access-scopes
  config.embedded_app = true
  config.after_authenticate_job = { job: 'AfterAuthenticateJob' }
  config.api_version = '2022-07'
  config.shop_session_repository = 'Shop'

  config.reauth_on_access_scope_changes = true

  config.root_url = '/api'
  config.login_url = '/api/auth'
  config.login_callback_url = '/api/auth/callback'
  config.embedded_redirect_url = '/ExitIframe'

  # You may want to charge merchants for using your app. Setting the billing configuration will cause the Authenticated
  # controller concern to check that the session is for a merchant that has an active one-time payment or subscription.
  # If no payment is found, it starts off the process and sends the merchant to a confirmation URL so that they can
  # approve the purchase.
  #
  # Learn more about billing in our documentation: https://shopify.dev/apps/billing
  # config.billing = ShopifyApp::BillingConfiguration.new(
  #   charge_name: "My app billing charge",
  #   amount: 5,
  #   interval: ShopifyApp::BillingConfiguration::INTERVAL_ANNUAL,
  #   currency_code: "USD", # Only supports USD for now
  # )

  config.api_key = ENV.fetch('SHOPIFY_API_KEY', '').presence
  config.secret = ENV.fetch('SHOPIFY_API_SECRET', '').presence

  if defined? Rails::Server
    raise('Missing SHOPIFY_API_KEY. See https://github.com/Shopify/shopify_app#requirements') unless config.api_key
    raise('Missing SHOPIFY_API_SECRET. See https://github.com/Shopify/shopify_app#requirements') unless config.secret
  end
end

Rails.application.config.after_initialize do
  if ShopifyApp.configuration.api_key.present? && ShopifyApp.configuration.secret.present?
    ShopifyAPI::Context.setup(
      api_key: ShopifyApp.configuration.api_key,
      api_secret_key: ShopifyApp.configuration.secret,
      api_version: ShopifyApp.configuration.api_version,
      host_name: URI(ENV.fetch('HOST', '')).host || '',
      scope: ShopifyApp.configuration.scope,
      is_private: !ENV.fetch('SHOPIFY_APP_PRIVATE_SHOP', '').empty?,
      is_embedded: ShopifyApp.configuration.embedded_app,
      session_storage: ShopifyApp::SessionRepository,
      logger: Rails.logger,
      private_shop: ENV.fetch('SHOPIFY_APP_PRIVATE_SHOP', nil),
      user_agent_prefix: "ShopifyApp/#{ShopifyApp::VERSION}"
    )

    ShopifyApp::WebhooksManager.add_registrations
  end
end
