# frozen_string_literal: true

# Accepts GraphQL data from Shopify and returns
# a TryOnify Order instance. Data should be from
# within "node" level

class OrderBuild < ApplicationService
  def initialize(shop_id:, data:)
    super()
    @data = data
    @shop_id = shop_id
  end

  def call
    build_order
  end

  private

  def build_order
    order = {
      shop_id: @shop_id,
      shopify_id: @data.dig("id"),
      due_date: @data.dig("paymentTerms", "paymentSchedules", "edges", 0, "node", "dueAt"),
      name: @data.dig("name"),
      financial_status: @data.dig("displayFinancialStatus"),
      email: @data.dig("customer", "email"),
      shopify_created_at: @data.dig("createdAt"),
      shopify_updated_at: @data.dig("updatedAt"),
      mandate_id: @data.dig("paymentCollectionDetails", "vaultedPaymentMethods", 0, "id"),
      fulfillment_status: @data.dig("displayFulfillmentStatus"),
      closed_at: @data.dig("closedAt"),
      cancelled_at: @data.dig("cancelledAt"),
      fully_paid: @data.dig("fullyPaid"),
      total_outstanding: @data.dig("totalOutstandingSet", "shopMoney", "amount"),
      ip_address: @data.dig("clientIp"),
      tags: @data.dig("tags"),
    }

    shipping_address = @data.dig("shippingAddress")
    shipping_address_attributes = {
      address1: shipping_address.dig("address1"),
      address2: shipping_address.dig("address2"),
      city: shipping_address.dig("city"),
      zip: shipping_address.dig("zip"),
      province: shipping_address.dig("province"),
      province_code: shipping_address.dig("provinceCode"),
      country: shipping_address.dig("country"),
      country_code: shipping_address.dig("countryCodeV2"),
    }

    order[:line_items_attributes] = line_items(@data)
    order[:shipping_address_attributes] = shipping_address_attributes
    order
  end

  def line_items(order)
    line_items_attributes = []
    order.dig("lineItems", "edges").each do |line_item|
      line_item_node = line_item.dig("node")
      selling_plan = SellingPlan.find_by(shopify_id: line_item_node.dig("sellingPlan", "sellingPlanId"))
      line_items_attributes << {
        shopify_id: line_item_node.dig("id"),
        title: line_item_node.dig("title"),
        variant_title: line_item_node.dig("variantTitle"),
        image_url: line_item_node.dig("image", "url"),
        quantity: line_item_node.dig("quantity"),
        unfulfilled_quantity: line_item_node.dig("unfulfilledQuantity"),
        restockable: line_item_node.dig("restockable"),
        selling_plan_id: selling_plan&.id,
      }
    end
    line_items_attributes
  end
end
