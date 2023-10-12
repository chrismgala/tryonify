# frozen_string_literal: true

class Shopify::Returns::SaveFromWebhook < ApplicationService
  def initialize(order, webhook)
    super()
    @order = order
    @webhook = webhook
  end

  def call
    Return.create!(
      shopify_id: @webhook['admin_graphql_api_id'],
      status: 'closed',
      shop: @order.shop,
      order: @order,
      return_line_items_attributes: @webhook['return_line_items'].map do |return_line_item|
        line_item = LineItem.find_by(shopify_id: return_line_item.dig('fulfillment_line_item', 'line_item', 'admin_graphql_api_id'))
        {
          shopify_id: return_line_item['admin_graphql_api_id'],
          quantity: return_line_item['quantity'],
          line_item: line_item,
          fulfillment_line_item_id: return_line_item.dig('fulfillment_line_item', 'admin_graphql_api_id'),
        }
      end
    )
  end
end