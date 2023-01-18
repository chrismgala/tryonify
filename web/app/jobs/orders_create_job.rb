# frozen_string_literal: true

class OrdersCreateJob < ApplicationJob
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
      fetch_order = FetchOrder.new(id: "gid://shopify/Order/#{webhook["id"]}", check_selling_plan: true)
      fetch_order.call

      return unless fetch_order.has_selling_plan

      order = fetch_order.order

      order_attributes = {
        shop_id: shop.id,
        shopify_id: order.dig("legacyResourceId"),
        shopify_created_at: order.dig("createdAt"),
        shopify_updated_at: order.dig("updatedAt"),
        name: order.dig("name"),
        due_date: order.dig("paymentTerms", "paymentSchedules", "edges", 0, "node", "dueAt"),
        closed_at: order.dig("closedAt"),
        cancelled_at: order.dig("cancelledAt"),
        financial_status: order["displayFinancialStatus"],
        fulfillment_status: order["displayFulfillmentStatus"],
        email: order.dig("customer", "email"),
        mandate_id: order.dig("paymentCollectionDetails", "vaultedPaymentMethods", 0, "id"),
        fully_paid: order.dig("fullyPaid"),
        total_outstanding: order.dig("totalOutstandingSet", "shopMoney", "amount"),
        ip_address: order.dig("clientIp"),
      }

      shipping_address = {
        address1: order.dig("shippingAddress", "address1"),
        address2: order.dig("shippingAddress", "address2"),
        city: order.dig("shippingAddress", "city"),
        country: order.dig("shippingAddress", "country"),
        country_code: order.dig("shippingAddress", "countryCodeV2"),
        province: order.dig("shippingAddress", "province"),
        province_code: order.dig("shippingAddress", "provinceCode"),
        zip: order.dig("shippingAddress", "zip"),
      }

      service = CreateOrUpdateOrder.new(order_attributes, shipping_address, order.dig("tags"))
      service.call
    end
  end
end
