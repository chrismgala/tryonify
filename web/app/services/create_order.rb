# frozen_string_literal: true

# Create an order from Shopify ID
class CreateOrder
  class InvalidRequest < StandardError; end

  attr_accessor :order, :error

  def initialize(shop:, order_id:)
    @shop = shop
    @order_id = order_id
    @order = nil
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    begin
      create_order
    rescue StandardError => e
      Rails.logger.error("[CreateOrder Failed]: #{e}")
      @error = e
    end
  end

  def hasNextPage
    @order.dig('lineItems', 'pageInfo', 'hasNextPage')
  end

  def fetch_order(cursor: nil)
    query = <<~QUERY
      query fetchOrder($id: ID!, $cursor: String) {
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
            lineItems(first: 100, after: $cursor) {
              edges {
                node {
                  sellingPlan {
                    sellingPlanId
                  }
                }
              }
              pageInfo {
                hasNextPage
                endCursor
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
      id: "gid://shopify/Order/#{@order_id}",
      cursor: cursor
    }

    response = @client.query(query: query, variables: variables)

    raise CreateOrder::InvalidRequest, response.body.dig('errors', 0, 'message') and return unless response.body['errors'].nil?

    return response.body.dig('data', 'order')
  end

  def create_order
    cursor = @order ? @order.dig('lineItems', 'pageInfo', 'endCursor') : nil
    
    @order = fetch_order(cursor: cursor)

    if has_selling_plan(@order)
      order = Order.new(
        shopify_id: @order_id,
        name: @order.dig('name'),
        due_date: @order.dig('paymentTerms', 'paymentSchedules', 'edges', 0, 'node', 'dueAt'),
        shop: @shop,
        status: @order['displayFinancialStatus'],
        email: @order.dig('customer', 'email')
      )

      order.save!

      KlaviyoEvent.new(@shop).call(
        event: 'TryOnify Order Created',
        email: @order.dig('customer', 'email'),
        properties: {
          'order_id': @order.dig('name'),
          'amount': @order.dig('totalPriceSet', 'shopMoney', 'amount')
        }
      )
    elsif hasNextPage
      create_order
    else
      @order = nil
    end
  end

  def has_selling_plan(order)
    return false if order.blank?
    line_items = order.dig('lineItems', 'edges')
    selling_plan_ids = line_items.map {|x| x.dig('node', 'sellingPlan', 'sellingPlanId')}
    selling_plan_ids.length > 0
  end
end