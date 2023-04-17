# frozen_string_literal: true

class OrderAuthorize < ApplicationService
  def initialize(order)
    super()
    @order = order
    @authorization = nil
    @authorization_transaction = nil
  end

  def call
    authorize if authorize_allowed?
  end

  private

  def authorize_allowed?
    @order.total_outstanding.positive? && !@order.fully_paid && !@order.authorized?
  end

  def authorize
    @authorization = OrderCreateMandatePayment.call(order: @order, auto_capture: false)

    schedule_update if @authorization
  end

  def schedule_update
    FetchPaymentStatusJob.set(wait: 2.minutes).perform_later(@authorization.id)
  end
end
