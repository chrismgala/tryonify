# frozen_string_literal: true

class OrderAuthorizeJob < ActiveJob::Base
  sidekiq_options retry: 3

  # Retry job with exponential backoff
  sidekiq_retry_in do |count|
    60 * (count + 1)
  end

  sidekiq_retries_exhausted do |job, _ex|
    logger.error("Failed #{job["class"]} with #{job["args"]}: #{job["error_message"]}")
  end

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
