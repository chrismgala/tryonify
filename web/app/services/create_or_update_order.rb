# frozen_string_literal: true

# Update an order from Shopify ID
class CreateOrUpdateOrder
  class InvalidRequest < StandardError; end

  attr_accessor :order, :error

  FETCH_ORDER_QUERY = <<~QUERY
    query fetchOrder($id: ID!, $after: String) {
      order(id: $id) {
        ...on Order {
          id
          name
          closedAt
          displayFinancialStatus
          displayFulfillmentStatus
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
          paymentCollectionDetails {
            vaultedPaymentMethods {
              id
            }
          }
          lineItems(first: 10, after: $after) {
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

  def initialize(shop_id:, order_id:)
    @shop_id = shop_id
    @order_id = order_id
    @order = nil
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    @order = fetch_order

    existing_order = Order.find_by(shopify_id: @order_id)

    order_attributes = {
      name: @order.dig('name'),
      due_date: @order.dig('paymentTerms', 'paymentSchedules', 'edges', 0, 'node', 'dueAt'),
      closed_at: @order.dig('closedAt'),
      financial_status: @order['displayFinancialStatus'],
      fulfillment_status: @order['displayFulfillmentStatus'],
      email: @order.dig('customer', 'email'),
      mandate_id: @order.dig('paymentCollectionDetails', 'vaultedPaymentMethods', 0, 'id')
    }

    if existing_order
      existing_order.update(order_attributes)
    elsif selling_plan?(@order)
      order_attributes.shop_id = @shop_id
      new_order = Order.create!(order_attributes)

      if new_order
        KlaviyoEvent.new(@shop).call(
          event: 'TryOnify Order Created',
          email: @order.dig('customer', 'email'),
          properties: {
            'order_id': @order.dig('name'),
            'amount': @order.dig('totalPriceSet', 'shopMoney', 'amount')
          }
        )
      end
    end
  rescue StandardError => e
    Rails.logger.error("[CreateOrUpdateOrder Failed]: #{e}")
    @error = e
    raise @error
  end

  def fetch_order(after = nil)
    query = FETCH_ORDER_QUERY

    variables = {
      id: "gid://shopify/Order/#{@order_id}",
      after:
    }

    response = @client.query(query:, variables:)

    unless response.body['errors'].nil?
      raise CreateOrUpdateOrder::InvalidRequest,
            response.body.dig('errors', 0, 'message') and return
    end

    response.body.dig('data', 'order')
  end

  # Page through line items looking for selling plan
  def selling_plan?(order)
    line_items = order.dig('lineItems', 'edges')
    selling_plan_ids = line_items.map { |x| x.dig('node', 'sellingPlan', 'sellingPlanId') }

    if selling_plan_ids.length.positive?
      true
    elsif order.dig('lineItems', 'pageInfo', 'hasNextPage')
      updated_order = fetch_order(order.dig('lineItems', 'pageInfo', 'endCursor'))
      selling_plan?(updated_order)
    else
      false
    end
  end
end
