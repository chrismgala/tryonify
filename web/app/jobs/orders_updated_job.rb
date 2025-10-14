# frozen_string_literal: true

class OrdersUpdatedJob < ApplicationJob
  def perform(shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    shop.with_shopify_session do
      order = Order.find_by(shopify_id: webhook["admin_graphql_api_id"])

      if order
        order.update!({
          name: webhook.dig("name"),
          email: webhook.dig("customer", "email"),
          payment_terms_id: "gid://shopify/PaymentTerms/#{webhook.dig("payment_terms", "id")}",
          due_date: webhook.dig("payment_terms", "payment_schedules", -1, "due_at"),
          shopify_updated_at: webhook.dig("updated_at"),
          closed_at: webhook.dig("closed_at"),
          cancelled_at: webhook.dig("cancelled_at"),
          financial_status: webhook.dig("financial_status")&.upcase,
          fulfillment_status: webhook.dig("fulfillment_status")&.upcase,
          fully_paid: webhook.dig("financial_status")&.upcase == "PAID" ? true : false,
          total_outstanding: webhook.dig("total_outstanding"),
          tags: webhook.dig("tags").split(",")
        })
      end
    end
  end
end
