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
                "financial_status:PENDING AND updated_at:>'#{shop.orders_updated_at}'"
              else
                'financial_status:PENDING'
              end

      # Fetch pending orders since last check was done
      service = FetchOrders.new({
                                  first: 20,
                                  after: cursor,
                                  query:
                                })
      service.call

      order_edges = service.orders.dig('edges')

      # Step execution if there are no orders
      return unless order_edges.length > 0

      # Create an array of orders with selling plans
      order_array = []
      order_edges.each do |order|
        next unless has_selling_plan(order['node'])

        order_array.push({
                           shopify_id: order.dig('node', 'legacyResourceId'),
                           name: order.dig('node', 'name'),
                           due_date: order.dig('node', 'paymentTerms', 'paymentSchedules', 'nodes', 0, 'dueAt'),
                           shopify_created_at: order.dig('node', 'createdAt'),
                           shop_id: shop.id,
                           financial_status: order.dig('node', 'displayFinancialStatus'),
                           email: order.dig('node', 'customer', 'email')
                         })
      end

      if order_array.length > 0
        Order.upsert_all(
          order_array,
          unique_by: :shopify_id
        )
      end

      # Create a job for the next page of orders
      if service.orders.dig('pageInfo', 'hasNextPage')
        FetchExistingOrdersJob.perform_later(shop.id, service.orders.dig('pageInfo', 'endCursor'))
      else
        shop.update(orders_updated_at: DateTime.now)
      end
    end
  end

  def has_selling_plan(order)
    return false if order.blank?

    order.dig('paymentTerms', 'paymentSchedules', 'nodes', 0, 'dueAt')
  end
end
