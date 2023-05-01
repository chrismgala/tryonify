# frozen_string_literal: true

class OrderTransactionFetch < ApplicationService
  attr_accessor :error

  FETCH_ORDER_TRANSACTION_QUERY = <<~QUERY
    query fetchTransaction($id: ID!) {
      order(id: $id) {
        transactions(first: 20) {
          id
          paymentId
          parentTransaction {
            id
          }
          receiptJson
          kind
          errorCode
          authorizationExpiresAt
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
    response.body.dig("data", "order", "transactions")&.each do |transaction|
      parent_transaction = @order.transactions.find_by(shopify_id: transaction.dig("parentTransaction", "id"))
      @order.transactions.find_or_create_by!(shopify_id: transaction["id"]) do |t|
        t.parent_transaction = parent_transaction if parent_transaction
        t.payment_id = transaction["paymentId"]
        t.receipt = transaction["receiptJson"]
        t.kind = transaction["kind"].downcase
        t.amount = transaction.dig("amountSet", "shopMoney", "amount")
        t.authorization_expires_at = transaction["authorizationExpiresAt"]
        t.error = transaction["errorCode"]
      end
      parent_transaction&.update!(voided: true)
    end
  rescue StandardError => e
    Rails.logger.error("[OrderTransactionFetch]: #{e.message}")
    @error = e.message
  end
end
