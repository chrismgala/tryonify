# frozen_string_literal: true

class OrderCapture < ApplicationService
  ORDER_CAPTURE_QUERY = <<~QUERY
    mutation orderCapture($input: OrderCaptureInput!) {
      orderCapture(input: $input) {
        transaction {
          id
          paymentId
          receiptJson
          kind
          amountSet {
            shopMoney {
              amount
            }
          }
          gateway
          errorCode
          status
        }
        userErrors {
          field
          message
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
    capture_payment
  rescue StandardError => e
    Rails.logger.error("[OrderCapture id=#{@order.id}]: #{e.message}")
  end

  private

  def capture_payment
    Rails.logger.info("[OrderCapture id=#{@order.id}]: Capturing payment")
    authorization = @order.latest_authorization

    if authorization.nil?
      Rails.logger.error("[OrderCapture id=#{@order.id}]: No authorization found for order")
      return
    end

    if authorization.authorization_expires_at < Time.current
      Rails.logger.warn("[OrderCapture id=#{@order.id}]: Authorization expired for order")
    end

    payment = Payment.new(
      idempotency_key: "order-#{@order.id}-#{SecureRandom.hex(10)}",
      order_id: @order.id,
      parent_transaction: authorization,
      kind: :payment,
    )

    response = @client.query(query: ORDER_CAPTURE_QUERY, variables: {
      input: {
        id: @order.shopify_id,
        amount: authorization.amount,
        parentTransactionId: authorization.shopify_id,
      },
    })

    response.body.dig("data", "orderCapture", "userErrors")&.each do |error|
      Rails.logger.error("[OrderCapture ID: #{@order.id}]: #{error["message"]}")
      payment.error = "#{payment.error} #{error["message"]}"
      payment.status = "ERROR"
      @order.ignore!
      return
    end

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    shopify_transaction = response.body.dig("data", "orderCapture", "transaction")
    payment.payment_reference_id = shopify_transaction["paymentId"]
    payment.status = shopify_transaction["status"]

    # Save or update transaction data
    @order.transactions.find_or_create_by!(shopify_id: shopify_transaction["id"]) do |t|
      t.order_id = @order.id
      t.payment_id = shopify_transaction["paymentId"]
      t.receipt = shopify_transaction["receiptJson"]
      t.kind = shopify_transaction["kind"].downcase
      t.amount = shopify_transaction.dig("amountSet", "shopMoney", "amount")
      t.status = shopify_transaction["status"].downcase
      t.gateway = shopify_transaction["gateway"]
      t.error = shopify_transaction["errorCode"]
    end

    Rails.logger.info("[OrderCapture id=#{@order.id}]: Payment captured")

    payment if payment.save!
  end
end
