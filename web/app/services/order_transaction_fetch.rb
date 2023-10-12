# frozen_string_literal: true

class OrderTransactionFetch < ApplicationService
  attr_accessor :error

  FETCH_ORDER_TRANSACTION_QUERY = <<~QUERY
    query fetchTransaction($id: ID!) {
      order(id: $id) {
        transactions(first: 30) {
          id
          paymentId
          parentTransaction {
            id
          }
          createdAt
          receiptJson
          kind
          errorCode
          authorizationExpiresAt
          gateway
          status
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
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
  end

  def call
    fetch_order_transaction
  end

  private

  def fetch_order_transaction
    response = @client.query(query: FETCH_ORDER_TRANSACTION_QUERY, variables: { id: @order.shopify_id })

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  rescue StandardError => e
    Rails.logger.error("[OrderTransactionFetch]: #{e.message}")
    @error = e.message
    raise e
  end
end
