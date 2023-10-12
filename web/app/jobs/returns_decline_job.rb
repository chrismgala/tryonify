class ReturnsDeclineJob < ActiveJob::Base
  extend ShopifyAPI::Webhooks::Handler

  class << self
    def handle(topic:, shop:, body:)
      perform_later(topic:, shop_domain: shop, webhook: body)
    end
  end

  def perform(topic:, shop_domain:, webhook:)
    return_item = Return.find_by(shopify_id: webhook['admin_graphql_api_id'])

    if return_item
      return_item.status = webhook['status']
      return_item.save!
    end
  end
end