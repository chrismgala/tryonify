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
        "-status:closed AND created_at:>'#{shop.orders_updated_at}'"
      else
        "-status:closed"
      end

      # Fetch pending orders since last check was done
      service = FetchOrders.new({
        first: 20,
        after: cursor,
        query:,
      })
      service.call

      order_edges = service.orders.dig("edges")

      # Step execution if there are no orders
      return unless order_edges.length > 0

      # Create an array of orders with selling plans
      order_array = []
      order_edges.each do |order|
        next unless has_selling_plan?(order["node"])

        order_array.push({
          shopify_id: order.dig("node", "legacyResourceId"),
          name: order.dig("node", "name"),
          due_date: order.dig("node", "paymentTerms", "paymentSchedules", "nodes", 0, "dueAt"),
          shopify_created_at: order.dig("node", "createdAt"),
          shopify_updated_at: order.dig("node", "updatedAt"),
          shop_id: shop.id,
          financial_status: order.dig("node", "displayFinancialStatus"),
          email: order.dig("node", "customer", "email"),
          closed_at: order.dig("node", "closedAt"),
          fully_paid: order.dig("node", "fullyPaid"),
          total_outstanding: order.dig("node", "totalOutstandingSet", "shopMoney", "amount"),
        })
      end

      if order_array.length > 0
        Order.upsert_all(
          order_array,
          unique_by: :shopify_id
        )
      end

      # Create a job for the next page of orders
      if service.orders.dig("pageInfo", "hasNextPage")
        FetchExistingOrdersJob.perform_later(shop.id, service.orders.dig("pageInfo", "endCursor"))
      else
        latest_order = shop.orders.order(shopify_created_at: :desc).first
        shop.update(orders_updated_at: latest_order.shopify_created_at) if latest_order
      end
    end
  end

  # Page through line items looking for selling plan
  def has_selling_plan?(order)
    line_items = order.dig("lineItems", "edges")
    selling_plan_ids = line_items.select { |x| x.dig("node", "sellingPlan", "sellingPlanId") }
      .map { |x| x.dig("node", "sellingPlan", "sellingPlanId") }

    if selling_plan_ids.length.positive? && SellingPlan.where(shopify_id: selling_plan_ids).any?
      true
    elsif order.dig("lineItems", "pageInfo", "hasNextPage")
      service = FetchOrder.new(order.dig("id"), order.dig("lineItems", "pageInfo", "endCursor"))
      service.call

      if service.order
        updated_order = service.order
        has_selling_plan?(updated_order)
      else
        raise "Could not fetch order #{order.dig("id")}"
      end
    else
      false
    end
  end
end
