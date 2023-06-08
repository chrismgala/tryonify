# frozen_string_literal: true

# This service is used to create a mandate payment for an order on Shopify.
# It can also be used to authorize a payment by setting the autoCapture flag to false.
# Returns a Payment object if successful, otherwise returns nil.
class OrderCreateMandatePayment < ApplicationService
  attr_accessor :error

  CREATE_MANDATE_PAYMENT_QUERY = <<~QUERY
    mutation orderCreateMandatePayment($id: ID!, $autoCapture: Boolean!, $idempotencyKey: String!, $mandateId: ID!) {
      orderCreateMandatePayment(id: $id, autoCapture: $autoCapture, idempotencyKey: $idempotencyKey, mandateId: $mandateId) {
        paymentReferenceId
        userErrors {
          field
          message
        }
      }
    }
  QUERY

  def initialize(order:, auto_capture: true)
    super()
    @order = order
    @auto_capture = auto_capture
    session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
  end

  def call
    create_mandate_payment if @order.mandate_id
  rescue StandardError => e
    Rails.logger.error("[OrderCreateMandatePayment Failed id=#{@order.id}]: #{e.message}")
    nil
  end

  private

  def create_mandate_payment
    Rails.logger.info("[OrderCreateMandatePayment id=#{@order.id} auto_capture=#{@auto_capture}]: Creating mandate payment")

    payment = Payment.new(
      idempotency_key: "order-#{@order.id}-#{SecureRandom.hex(10)}",
      order_id: @order.id,
      kind: @auto_capture ? :payment : :authorization,
    )

    query = CREATE_MANDATE_PAYMENT_QUERY

    variables = {
      id: @order.shopify_id,
      idempotencyKey: payment.idempotency_key,
      autoCapture: @auto_capture,
      mandateId: @order.mandate_id,
    }

    response = @client.query(query:, variables:)

    unless response.body.dig("data", "orderCreateMandatePayment", "userErrors", 0, "message").nil?
      raise response.body.dig("data", "orderCreateMandatePayment", "userErrors", 0, "message") and return
    end

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    Rails.logger.info("[OrderCreateMandatePayment id=#{@order.id} auto_capture=#{@auto_capture}]: Mandate payment created")

    payment_reference_id = response.body.dig("data", "orderCreateMandatePayment", "paymentReferenceId")
    payment.payment_reference_id = payment_reference_id
    payment if payment.save!
  end
end
