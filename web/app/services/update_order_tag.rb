# frozen_string_literal: true

# Create an order from Shopify ID
class UpdateOrderTag
  class InvalidRequest < StandardError; end

  attr_accessor :order, :error

  def initialize(order_id, existing_tags = [])
    @order_id = order_id
    @existing_tags = existing_tags || []
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

    variables = {
      input: {
        id: @order_id,
        tags: @existing_tags << "TryOnify Order",
      },
    }

    response = @client.query(query:, variables:)

    unless response.body["errors"].nil?
      raise UpdateOrderTag::InvalidRequest,
        response.body.dig("errors", 0, "message") and return
    end
  rescue StandardError => e
    Rails.logger.error("[UpdateOrderTag Failed]: #{e.message}")
    @error = e.message
    raise @error
  end
end
