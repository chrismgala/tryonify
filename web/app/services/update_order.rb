# frozen_string_literal: true

# Update an order from Shopify ID
class UpdateOrder
  class InvalidRequest < StandardError; end

  attr_accessor :order, :error

  def initialize(shop, order_id)
    @shop = shop
    @order_id = order_id
    @order = nil
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    begin
      update_order
    rescue StandardError => e
      Rails.logger.error("[UpdateOrder Failed]: #{e}")
      @error = e
    end
  end

  def fetch_order
    query = <<~QUERY
      query fetchOrder($id: ID!) {
        order(id: $id) {
          ...on Order {
            id
            name
            displayFinancialStatus
            customer {
              email
            }
            paymentTerms {
              paymentSchedules(first: 1) {
                edges {
                  node {
                    dueAt
                  }
                }
              }
            }
            totalPriceSet {
              shopMoney {
                amount
              }
            }
          }
        }
      }
    QUERY

    variables = {
      id: "gid://shopify/Order/#{@order_id}"
    }

    response = @client.query(query: query, variables: variables)

    raise UpdateOrder::InvalidRequest, response.body.dig('errors', 0, 'message') and return unless response.body['errors'].nil?

    return response.body.dig('data', 'order')
  end

  def update_order
    existing_order = Order.find_by!(shopify_id: @order_id)

    if existing_order
      @order = fetch_order

      existing_order.update(
        name: @order.dig('name'),
        due_date: @order.dig('paymentTerms', 'paymentSchedules', 'edges', 0, 'node', 'dueAt'),
        status: @order['displayFinancialStatus'],
        email: @order.digt('customer', 'email')
      )
    end
  end
end