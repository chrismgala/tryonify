class ShopUpdateJob < ActiveJob::Base
  extend ShopifyAPI::Webhooks::Handler

  discard_on ActiveRecord::RecordNotFound

  class << self
    def handle(topic:, shop:, body:)
      perform_later(topic:, shop_domain: shop, webhook: body)
    end
  end

  def perform(topic:, shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    shop.update({
                  email: webhook.dig('email')
                })
  end
end
