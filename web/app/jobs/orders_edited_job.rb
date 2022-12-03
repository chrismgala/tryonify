# frozen_string_literal: true

class OrdersEditedJob < ApplicationJob
  extend ShopifyAPI::Webhooks::Handler

  class << self
    def handle(topic:, shop:, body:)
      perform_later(topic:, shop_domain: shop, webhook: body)
    end
  end

  def perform(topic:, shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    shop.with_shopify_session do
      order = Order.find_by(shopify_id: webhook["id"])

      if order
        order.update!({
          name: webhook.dig("name"),
          email: webhook.dig("customer", "email"),
          due_date: webhook.dig("payment_terms", "payment_schedules", 0, "due_at"),
          closed_at: webhook.dig("closed_at"),
          financial_status: webhook.dig("financial_status")&.upcase,
          fulfillment_status: webhook.dig("fulfillment_status")&.upcase,
          fully_paid: webhook.dig("fulfillment_status")&.upcase == "PAID" ? true : false,
          total_outstanding: webhook.dig("total_outstanding"),
        })

        service = ProcessReturnFromWebhook.new(webhook)
        service.call
      end
    end
  end
end
