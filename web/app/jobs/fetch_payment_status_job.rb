# frozen_string_literal: true

class FetchPaymentStatusJob < ApplicationJob
  sidekiq_options retry: 3

  def perform(payment_id)
    payment = Payment.find(payment_id)

    if payment.nil?
      logger.error("#{self.class} failed: cannot find payment with ID '#{payment_id}'")
      return
    end

    payment.order.shop.with_shopify_session do
      service = FetchPaymentStatus.new(payment_id)
      service.call
    end
  end
end
