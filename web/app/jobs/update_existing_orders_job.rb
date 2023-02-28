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
        persisted_order = Order.find_by(shopify_id: order.dig("legacyResourceId"))

        next unless persisted_order

        persisted_order.name = order.dig("name")
        persisted_order.due_date = order.dig("paymentTerms", "paymentSchedules", "nodes", 0, "dueAt")
        persisted_order.shopify_created_at = order.dig("createdAt")
        persisted_order.shopify_updated_at = order.dig("updatedAt")
        persisted_order.shop_id = shop.id
        persisted_order.financial_status = order.dig("displayFinancialStatus")
        persisted_order.email = order.dig("customer", "email")
        persisted_order.closed_at = order.dig("closedAt")
        persisted_order.cancelled_at = order.dig("cancelledAt")
        persisted_order.fully_paid = order.dig("fullyPaid")
        persisted_order.total_outstanding = order.dig("totalOutstandingSet", "shopMoney", "amount")

        persisted_order.save!
      end
    end
  end
end
