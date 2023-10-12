# frozen_string_literal: true

class PaymentTermsUpdateJob < ApplicationJob
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

    
    order = Order.find_by(payment_terms_id: "gid://shopify/PaymentTerms/#{webhook["id"]}")

    if order
      order.update!(due_date: webhook.dig("payment_schedules", 0, "due_at"))
    end
  end
end
