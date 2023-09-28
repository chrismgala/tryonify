# frozen_string_literal: true

# Create an order from Shopify ID
class UpdateReturnOrderNote
  class InvalidRequest < StandardError; end

  attr_accessor :order, :error

  def initialize(shop_id, return_id)
    @shop = Shop.find(shop_id)
    @return = Return.find(return_id)
    @order = nil
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

    existing_order = fetch_order
    existing_note = existing_order.dig("note")

    variables = {
      input: {
        id: "gid://shopify/Order/#{@return.order.shopify_id}",
        note: "#{existing_note == "" ? "" : "#{existing_note}\n"}[Return Requested: #{@return.title} - #{@return.created_at.strftime("%m/%d/%Y")}]",
      },
    }

    response = @client.query(query: query, variables: variables)

    raise UpdateReturnOrderNote::InvalidRequest,
      response.body.dig("errors", 0, "message") and return unless response.body["errors"].nil?

    @order = response.body.dig("data", "order")
  rescue StandardError => e
    Rails.logger.error("[UpdateReturnOrderNote Failed]: #{e}")
    @error = e
  end

  def fetch_order
    service = FetchOrder.new(id: @return.order.shopify_id)
    service.call

    service.order
  end
end
