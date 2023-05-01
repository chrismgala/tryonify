# frozen_string_literal: true

class OrderSuggestedRefund < ApplicationService
  FETCH_SUGGESTED_REFUND = <<~QUERY
    query suggestedRefund($id: ID!) {
      order(id: $id) {
        suggestedRefund(suggestFullRefund: true) {
          amountSet {
            shopMoney {
              amount
            }
          }
        }
      }
    }
  QUERY

  def initialize(order)
    super()
    @order = order
    session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
  end

  def call
    fetch_suggested_refund
  end

  private

  def fetch_suggested_refund
    response = @client.query(query: FETCH_SUGGESTED_REFUND, variables: {
      id: @order.shopify_id,
    })
    suggested_refund = response.body.dig("data", "order", "suggestedRefund", "amountSet", "shopMoney", "amount")
    suggested_refund
  end
end
