# frozen_string_literal: true

class ValidateOrderJob < ActiveJob::Base
  def perform(order_id)
    order = Order.find(order_id)

    if order.nil?
      logger.error("#{self.class} failed: cannot find order with id #{order_id}")
      return
    end

    service = ValidateOrder.new(order)
    service.call
  end
end
