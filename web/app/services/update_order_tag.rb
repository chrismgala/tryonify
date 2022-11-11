# frozen_string_literal: true

# Create an order from Shopify ID
class UpdateOrderTag
  class InvalidRequest < StandardError; end

  attr_accessor :order, :error

  # Uses GraphQL Order object from Shopify
  def initialize(shop_id, shopify_order)
    @shop = Shop.find(shop_id)
    @shopify_order = shopify_order
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = <<~QUERY
      mutation updateOrder($input: OrderInput!) {
        orderUpdate(input: $input) {
          userErrors {
            message
            field
          }
        }
      }
    QUERY

    existing_tags = @shopify_order.dig('tags')

    variables = {
      input: {
        id: @shopify_order.dig('id'),
        tags: existing_tags << 'TryOnify Order'
      }
    }

    response = @client.query(query:, variables:)

    unless response.body['errors'].nil?
      raise UpdateOrderTag::InvalidRequest,
            response.body.dig('errors', 0, 'message') and return
    end
  rescue StandardError => e
    Rails.logger.error("[UpdateOrderTag Failed]: #{e.message}")
    @error = e.message
    raise @error
  end
end
