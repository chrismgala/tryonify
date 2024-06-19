# frozen_string_literal: true

class AfterAuthenticateJob < ActiveJob::Base
  def perform(shop_domain:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    shop.with_shopify_session do
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
