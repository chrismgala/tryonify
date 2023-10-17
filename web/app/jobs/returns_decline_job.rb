class ReturnsDeclineJob < ActiveJob::Base
  extend ShopifyAPI::Webhooks::Handler

  class << self
    def handle(topic:, shop:, body:)
      perform_later(topic:, shop_domain: shop, webhook: body)
    end
  end

  def perform(topic:, shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)
    
    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain #{shop_domain}")
      return
    end

    persisted_return = Return.find_by(shopify_id: webhook['admin_graphql_api_id'])
    if persisted_return
      persisted_return.status = webhook['status']
      persisted_return.save!
    end
  end
end