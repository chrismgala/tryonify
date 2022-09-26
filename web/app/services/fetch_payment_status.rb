# frozen_string_literal: true

class FetchPaymentStatus
  class InvalidRequest < StandardError; end

  PAYMENT_MANDATE_STATUS_QUERY = <<~QUERY
    query fetchPaymentStatus($orderId: ID!, $paymentReferenceId: String!) {
      orderPaymentStatus(orderId: $orderId, paymentReferenceId: $paymentReferenceId) {
        errorMessage
        status
      }
    }
  QUERY

  RETRY_STATUS = %i[RETRYABLE PROCESSING]

  attr_accessor :status, :error

  def initialize(payment_id)
    @payment = Payment.find(payment_id)
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = PAYMENT_MANDATE_STATUS_QUERY

    variables = {
      orderId: "gid://shopify/Order/#{@payment.order.shopify_id}",
      paymentReferenceId: @payment.payment_reference_id
    }

    response = @client.query(query:, variables:)

    unless response.body['errors'].nil?
      raise FetchPaymentStatus::InvalidRequest,
            response.body.dig('errors', 0, 'message') and return
    end

    @status = response.body.dig('data', 'orderPaymentStatus', 'status')
    @error = response.body.dig('data', 'orderPaymentStatus', 'error')

    @payment.update!(status: @status&.upcase, error: @error)

    if RETRY_STATUS.include? @status
      Rails.logger("[FetchPaymentStatus]: Retrying payment #{@payment.id}")
      FetchPaymentStatusJob.set(wait: 2.minutes).perform_later(@payment.id)
    end
  end
end
