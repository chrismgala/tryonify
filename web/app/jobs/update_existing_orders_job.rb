# frozen_string_literal: true

class UpdateExistingOrdersJob < ActiveJob::Base
  sidekiq_options retry: 1

  def perform(shop_id, ids)
    shop = Shop.find(shop_id)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    shop.with_shopify_session do
      # Fetch pending orders since last check was done
      service = FetchOrdersByNode.new(ids)
      service.call

      # Step execution if there are no orders
      return unless service.orders.length > 0

      # Create an array of orders with selling plans
      service.orders.each do |order|
        persisted_order = Order.find_by(shopify_id: order.dig("id"))

        next unless persisted_order

        built_order = OrderBuild.call(shop_id: shop.id, data: order)
        OrderUpdate.call(order_attributes: built_order, order: persisted_order)
      end
    end
  end
end
