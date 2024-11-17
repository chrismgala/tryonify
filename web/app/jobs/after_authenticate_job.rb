# frozen_string_literal: true

class AfterAuthenticateJob < ActiveJob::Base
  def perform(shop_domain:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    shop.with_shopify_session do
      session = ShopifyAPI::Context.active_session
      service = Shopify::Store::Fetch.call
      shopify_shop = service.body.dig('data', 'shop')

      shop.shopify_id = shopify_shop['id']
      shop.email = shopify_shop['email']
      shop.currency_code = shopify_shop['currencyCode']
      shop.save!

      # Set app metafield
      service = FetchAppSubscription.new
      service.call

      raise 'Could not get app' unless service.app

      mantle_client = Mantle::MantleClient.new(
        app_id: ENV["MANTLE_APP_ID"],
        api_key: ENV["MANTLE_APP_KEY"],
        customer_api_token: nil,
        api_url: 'https://appapi.heymantle.com/v1'
      )

      raise 'Could not create mantle client' unless mantle_client

      customer_response = mantle_client.identify(
        platform_id: shopify_shop['id'],
        myshopify_domain: shopify_shop['url'],
        access_token: session.access_token,
        name: shopify_shop['name'],
        email: shopify_shop['email']
      )

      logger.info("#{self.class} identified customer in Mantle with API token #{customer_response['apiToken']}")

      current_customer = mantle_client.get_customer
      logger.info("#{self.class} current customer: #{current_customer}")

      Shopify::Metafields::Create.call([{
        key: "appId",
        namespace: "settings",
        ownerId: service.app['id'],
        type: "string",
        value: service.app.dig('app', 'id').split('/').last
      }])

      # Configure metafield definitions
      Shopify::MetafieldDefinitions::ConfigureMetafieldDefinitions.call

      # Set max trial metafield
      Shopify::Validations::ConfigureCartValidation.call(max_trials: 3, enable: true) if shop.max_trial_items.blank?

      FetchExistingOrdersJob.perform_later(shop.id, nil)
      CreateExistingSellingPlanGroupsJob.perform_later(shop.id)
    end
  end
end
