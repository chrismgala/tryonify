# frozen_string_literal: true

class CreatePaymentJob < ApplicationJob
  def perform(order_id)
    order = Order.find(order_id)

    if order.nil?
      logger.error("#{self.class} failed: cannot find order with ID '#{order_id}'")
      return
    end

    order.shop.with_shopify_session do
      service = CreatePayment.new(order_id)
      service.call
    end
  end
end
