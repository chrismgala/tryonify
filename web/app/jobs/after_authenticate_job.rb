# frozen_string_literal: true

class AfterAuthenticateJob < ActiveJob::Base
  def perform(shop_domain:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    shop.with_shopify_session do
      shopify_shop = ShopifyAPI::Shop.all.first

      shop.email = shopify_shop.email
      shop.order_number_format_prefix = shopify_shop.order_number_format_prefix
      shop.order_number_format_suffix = shopify_shop.order_number_format_suffix
      shop.currency_code = shopify_shop.currency
      shop.save!
    end

    # Set max trial metafield
    Shopify::Validations::ConfigureCartValidation.call(max_trial: 3, enable: true) if shop.max_trial_items.blank?

    FetchExistingOrdersJob.perform_later(shop.id, nil)
    CreateExistingSellingPlanGroupsJob.perform_later(shop.id)
  end
end
