# frozen_string_literal: true

class OrderCapture < ApplicationService
  ORDER_CAPTURE_QUERY = <<~QUERY
    mutation orderCapture($input: OrderCaptureInput!) {
      orderCapture(input: $input) {
        transaction {
          id
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
    authorization = @order.authorization

    if authorization.nil?
      Rails.logger.error("[OrderCapture]: No authorization found for order #{@order.id}")
      return
    end
    puts authorization.inspect
    response = @client.query(query: ORDER_CAPTURE_QUERY, variables: {
      input: {
        id: @order.shopify_id,
        amount: authorization.amount,
        parentTransactionId: authorization.shopify_id,
      },
    })

    response.body.dig("data", "orderCapture", "userErrors")&.each do |error|
      Rails.logger.error("[OrderCapture]: #{error["message"]}")
    end
  rescue StandardError => e
    Rails.logger.error("[OrderCapture]: #{e.message}")
  end
end
