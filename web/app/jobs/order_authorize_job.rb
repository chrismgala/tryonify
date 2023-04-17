# frozen_string_literal: true

class OrderAuthorizeJob < ActiveJob::Base
  sidekiq_options retry: false

  def perform(order_id)
    order = Order.find(order_id)

    if order.nil?
      logger.error("#{self.class} failed: cannot find order with id #{order_id}")
      return
    end

    order.shop.with_shopify_session do
      OrderAuthorize.call(order)
    end
  end
end
