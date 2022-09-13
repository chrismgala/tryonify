class ShopUpdateJob < ActiveJob::Base
  extend ShopifyAPI::Webhooks::Handler

  discard_on ActiveRecord::RecordNotFound

  class << self
    def handle(topic:, shop:, body:)
      perform_later(topic: topic, shop_domain: shop, webhook: body)
    end
  end

  def perform(topic:, shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    shop.update({
      order_number_format_prefix: body.dig('order_number_format_prefix'),
      order_number_format_suffix: body.dig('order_number_format_suffix'),
      email: body.dig('email')
    })
  end
end
