# frozen_string_literal: true

class CreatePayment < ApplicationService
  attr_accessor :error

  def initialize(order_id)
    super()
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
    fetch_transactions

    # Check whether the charge should be made
    if can_charge?
      # Charge the remaining balance
      if @order.authorized?
        capture_authorization
      else
        create_mandate_payment
      end

      # Don't touch the order again after payment
      @order.ignore! if @order.ignored_at.nil?
    end
  end

  def can_charge?
    # Check that the order has not been ignored
    return false if @order.ignored?

    # Check that there is a due date
    return false unless @order.due_date

    # Check that the due date has passed
    return false if @order.due_date.after?(Time.current)

    # Make sure there are no returns that haven't been processed
    return_item = @order.returns.where(active: true).order(created_at: :desc).first
    if return_item
      # Check if the return grace period has passed
      grace_period = @order.shop.return_period
      deadline = return_item.created_at + grace_period.days

      return false unless deadline.before?(Time.current)
    end

    # Make sure order has actually been fulfilled
    # return false if @order.fulfillment_status != 'FULFILLED'

    # Order is not cancelled
    return false if @order.cancelled_at

    # Order is fully paid
    return false if @order.fully_paid

    # Check for previous payment attempt, anything other than AUTHORIZED
    # could be a failed payment or a payment that has been captured
    # return false if @order.payments.where.not(status: "AUTHORIZED").any?

    true
  end

  def create_mandate_payment
    @payment = OrderCreateMandatePayment.call(order: @order)
    schedule_update if @payment
  end

  def capture_authorization
    OrderCapture.call(@order)
  end

  def fetch_transactions
    OrderTransactionsUpdate.call(@order)
  end

  def update_order
    graphql_order = FetchOrder.call(id: @order.shopify_id)
    built_order = OrderBuild.call(shop_id: @order.shop_id, data: graphql_order.body.dig("data", "order"))
    OrderUpdate.call(order_attributes: built_order, order: @order)

    @order.reload
  end

  def schedule_update
    FetchPaymentStatusJob.set(wait: 2.minutes).perform_later(@payment.id)
  end
end
