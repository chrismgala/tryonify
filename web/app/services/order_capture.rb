# frozen_string_literal: true

class OrderCapture < ApplicationService
  ORDER_CAPTURE_QUERY = <<~QUERY
    mutation orderCapture($input: OrderCaptureInput!) {
      orderCapture(input: $input) {
        transaction {
          id
          paymentId
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
  end

  private

  def capture_payment
    authorization = @order.latest_authorization

    if authorization.nil?
      Rails.logger.error("[OrderCapture ID: #{@order.id}]: No authorization found for order")
      return
    end

    if authorization.authorization_expires_at < Time.current
      Rails.logger.error("[OrderCapture ID: #{@order.id}]: Authorization expired for order")
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
    end

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    payment_reference_id = response.body.dig("data", "orderCapture", "transaction", "paymentId")
    payment.payment_reference_id = payment_reference_id
    payment if payment.save!
  rescue StandardError => e
    Rails.logger.error("[OrderCapture ID: #{@order.id}]: #{e.message}")
  end
end
