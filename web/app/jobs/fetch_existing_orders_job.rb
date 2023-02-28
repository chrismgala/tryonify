# frozen_string_literal: true

class FetchExistingOrdersJob < ActiveJob::Base
  def perform(shop_id, cursor = nil)
    shop = Shop.find(shop_id)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    shop.with_shopify_session do
      query = if shop.orders_updated_at
        "-status:cancelled AND created_at:>'#{shop.orders_updated_at}'"
      else
        "-status:cancelled"
      end

      # Fetch pending orders since last check was done
      orders = FetchOrders.call({
        first: 20,
        after: cursor,
        query:,
      })

      # Step execution if there are no orders
      return unless orders&.body&.dig("data", "orders", "edges")

      # Create an array of orders with selling plans
      orders.body.dig("data", "orders", "edges").each do |order|
        built_order = OrderBuild.call(shop_id: shop.id, data: order.dig("node"))
        existing_order = Order.find_by(shopify_id: built_order[:shopify_id])

        if existing_order
          OrderUpdate.call(order_attributes: built_order, order: existing_order)
        else
          OrderCreate.call(built_order)
        end
      end

      # Create a job for the next page of orders
      if orders.body.dig("data", "pageInfo", "hasNextPage")
        FetchExistingOrdersJob.perform_later(shop.id, orders.body.dig("data", "pageInfo", "endCursor"))
      else
        latest_order = shop.orders.order(shopify_created_at: :desc).first
        shop.update(orders_updated_at: latest_order.shopify_created_at) if latest_order
      end
    end
  end
end
