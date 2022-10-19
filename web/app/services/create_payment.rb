# frozen_string_literal: true

class CreatePayment
  class UserError < StandardError; end
  class InvalidRequest < StandardError; end

  attr_accessor :payment, :error

  CREATE_MANDATE_PAYMENT_QUERY = <<~QUERY
    mutation orderCreateMandatePayment($id: ID!, $idempotencyKey: String!, $mandateId: ID!) {
      orderCreateMandatePayment(id: $id, idempotencyKey: $idempotencyKey, mandateId: $mandateId) {
        paymentReferenceId
        userErrors {
          field
          message
        }
      }
    }
  QUERY

  def initialize(order_id)
    @order = Order.find(order_id)
    @payment = nil
    @error = nil
    session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
  end

  def call
    return unless @order

    # Update order to make sure it has the latest details
    update_order
    # Check whether the charge should be made
    if can_charge?
      # Charge the remaining balance
      charge

      # Get status of payment
      schedule_update if @payment.save!
    end
  rescue CreatePayment::InvalidRequest => e
    Rails.logger.error("[CreatePayment Failed]: Order #{@order.id} - #{e}")
    @error = e
  end

  def can_charge?
    # Check that the due date has passed
    return false if @order.due_date.after? DateTime.current

    # Make sure there are no returns that haven't been processed
    returns = @order.returns.where(active: true)
    if returns.length.positive?
      # Check if the return grace period has passed
      grace_period_elapsed = false
      grace_period = @order.shop.return_period
      returns.each do |item|
        deadline = item.created_at + grace_period.days
        grace_period_elapsed = true if deadline.before? DateTime.current
      end

      return false unless grace_period_elapsed
    end

    # Make sure order has actually been fulfilled
    # return false if @order.fulfillment_status != 'FULFILLED'

    # Order is not closed
    return false if @order.closed_at

    true
  end

  def charge
    @payment = Payment.new(
      idempotency_key: "order-#{@order.id}-#{SecureRandom.hex(10)}",
      order_id: @order.id
    )

    query = CREATE_MANDATE_PAYMENT_QUERY

    variables = {
      id: "gid://shopify/Order/#{@order.shopify_id}",
      idempotencyKey: @payment.idempotency_key,
      mandateId: @order.mandate_id
    }

    response = @client.query(query:, variables:)

    unless response.body.dig('data', 'orderCreateMandatePayment', 'userErrors', 0, 'message').nil?
      raise CreatePayment::UserError,
            response.body.dig('data', 'orderCreateMandatePayment', 'userErrors', 0, 'message') and return
    end

    unless response.body['errors'].nil?
      raise CreatePayment::InvalidRequest,
            response.body.dig('errors', 0, 'message') and return
    end

    payment_reference_id = response.body.dig('data', 'orderCreateMandatePayment', 'paymentReferenceId')
    @payment.payment_reference_id = payment_reference_id
  end

  def update_order
    service = CreateOrUpdateOrder.new(shop_id: @order.shop_id, order_id: @order.shopify_id)
    service.call

    @order.reload
  end

  def schedule_update
    FetchPaymentStatusJob.set(wait: 2.minutes).perform_later(@order.payment.id)
  end
end
