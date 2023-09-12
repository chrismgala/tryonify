class ReturnsApproveJob < ActiveJob::Base
  extend ShopifyAPI::Webhooks::Handler

  class << self
    def handle(topic:, shop:, body:)
      perform_later(topic:, shop_domain: shop, webhook: body)
    end
  end

  def perform(topic:, shop_domain:, webhook:)
    order = Order.find_by(shopify_id: webhook.dig('order', 'admin_graphql_api_id'))
    
    if order.nil?
      return
    end
    
    shop = Shop.find_by(shopify_domain: shop_domain)
    
    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain #{shop_domain}")
      return
    end

    line_items = webhook['return_line_items'].each do |return_line_item|
      line_item = LineItem.find_by(shopify_id: return_line_item.dig('fulfillment_line_item', 'line_item', 'admin_graphql_api_id'))
      return unless line_item || line_item.selling_plan_id.present?
      persisted_return = Return.find_by(shopify_id: webhook['admin_graphql_api_id'])
      if persisted_return
        persisted_return.status = webhook['status']
        persisted_return.save!
      else
        Return.create!(
          shopify_id: webhook['admin_graphql_api_id'],
          status: 'closed',
          quantity: return_line_item.dig('quantity'),
          shop:,
          order:,
          line_item:
        )
      end
    end
  end
end