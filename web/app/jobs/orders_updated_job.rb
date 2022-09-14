# frozen_string_literal: true

class OrdersUpdatedJob < ApplicationJob
  extend ShopifyAPI::Webhooks::Handler

  class << self
    def handle(topic:, shop:, body:)
      perform_later(topic: topic, shop_domain: shop, webhook: body)
    end
  end

  def perform(topic:, shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    shop.with_shopify_session do
      order = Order.find_by(shopify_id: webhook['id'])

      if order
        order.update({
          name: webhook.dig('name'),
          email: webhook.dig('customer', 'email'),
          due_date: webhook.dig('payment_terms', 'payment_schedules', 0, 'due_at'),
          status: webhook.dig('financial_status')&.upcase
        })

        service = ProcessReturnFromWebhook.new(webhook)
        service.call
      end
    end
  end
end