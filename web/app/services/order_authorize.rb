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
    !@order.fully_paid && @order.cancelled_at.nil?
  end

  def authorize
    Rails.logger.info("[OrderAuthorize id=#{@order.id}]: Order authorizing")
    @authorization = OrderCreateMandatePayment.call(order: @order, auto_capture: false)

    if @authorization
      Rails.logger.info("[OrderAuthorize id=#{@order.id}]: Order successfully authorized")
      schedule_update
    end
  end

  def schedule_update
    FetchPaymentStatusJob.set(wait: 2.minutes).perform_later(@authorization.id)
  end
end
