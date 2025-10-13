# frozen_string_literal: true

class OrdersCreateJob < ApplicationJob
  def perform(shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    shop.with_shopify_session do
      graphql_order = FetchOrder.call(id: "gid://shopify/Order/#{webhook["id"]}")
      return unless graphql_order

      order = OrderBuild.call(shop_id: shop.id, data: graphql_order.body.dig("data", "order"))
      OrderCreate.call(order)
    end
  end
end
