# frozen_string_literal: true

class OrderCancelJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound

  def perform(order_id)
    order = Order.find(order_id)

    if order.nil?
      logger.error("#{self.class} failed: cannot find order with id '#{order_id}'")
      return
    end

    order.shop.with_shopify_session do
      OrderCancel.call(order)
    end
  end
end
