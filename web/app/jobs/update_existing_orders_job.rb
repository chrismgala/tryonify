# frozen_string_literal: true

class UpdateExistingOrdersJob < ActiveJob::Base
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
      order_array = []

      service.orders.each do |order|
        order_array.push({
          name: order.dig("name"),
          shopify_id: order.dig("legacyResourceId"),
          due_date: order.dig("paymentTerms", "paymentSchedules", "nodes", 0, "dueAt"),
          shopify_created_at: order.dig("createdAt"),
          shopify_updated_at: order.dig("updatedAt"),
          shop_id: shop.id,
          financial_status: order.dig("displayFinancialStatus"),
          email: order.dig("customer", "email"),
          closed_at: order.dig("closedAt"),
          cancelled_at: order.dig("cancelledAt"),
          fully_paid: order.dig("fullyPaid"),
          total_outstanding: order.dig("totalOutstandingSet", "shopMoney", "amount"),
        })
      end

      if order_array.length > 0
        Order.upsert_all(
          order_array,
          unique_by: :shopify_id
        )
      end
    end
  end
end
