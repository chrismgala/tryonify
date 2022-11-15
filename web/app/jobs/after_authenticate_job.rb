# frozen_string_literal: true

class AfterAuthenticateJob < ActiveJob::Base
  def perform(shop_domain:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    shop.with_shopify_session do
      shopify_shop = ShopifyAPI::Shop.all.first
      shop.email = shopify_shop.email
      shop.order_number_format_prefix = shopify_shop.order_number_format_prefix
      shop.order_number_format_suffix = shopify_shop.order_number_format_suffix
      shop.save!

      # Set max trial metafield
      service = CreateMetafield.new({
                                      key: 'maxTrialItems',
                                      namespace: 'settings',
                                      type: 'number_integer',
                                      value: shop.max_trial_items
                                    })
      service.call
    end

    FetchExistingOrdersJob.perform_later(shop.id, nil)
  end
end
