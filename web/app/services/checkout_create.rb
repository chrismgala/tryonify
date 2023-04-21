# frozen_string_literal: true

class CheckoutCreate < ApplicationService
  def initialize(id)
    super()
    @id = id
    @draft_order = nil
    session = ShopifyAPI::Context.active_session
    @shop = Shop.find_by(shopify_domain: session.shop)
  end

  def call
    if @shop.nil?
      raise "Shop not found" and return
    end

    fetch_draft_order
    create_checkout
  end

  private

  def fetch_draft_order
    @draft_order = DraftOrderFetch.call(@id)
  end

  def create_checkout
    return false unless @draft_order

    draft_order_id = @draft_order.body.dig("data", "draftOrder", "id")
    draft_order_name = @draft_order.body.dig("data", "draftOrder", "name")
    variant_ids = @draft_order.body.dig("data", "draftOrder", "lineItems", "edges").map do |edge|
      edge.dig("node", "variant", "id")
    end

    response = NodesFetch.call(variant_ids)
    selling_plans_by_id = {}

    response.body.dig("data", "nodes").map do |node|
      variant_id = node.dig("legacyResourceId")
      node.dig("sellingPlanGroups", "edges").each do |edge|
        edge.dig("node", "sellingPlans", "edges").each do |edge|
          selling_plan_id = edge.dig("node", "id")
          selling_plans_by_id[variant_id] = selling_plan_id.split("/").last.to_i
        end
      end
    end.flatten

    line_items = @draft_order.body.dig("data", "draftOrder", "lineItems", "edges").map do |edge|
      {
        variant_id: edge.dig("node", "variant", "legacyResourceId"),
        quantity: edge.dig("node", "quantity"),
        selling_plan_id: selling_plans_by_id[edge.dig("node", "variant", "legacyResourceId")],
      }
    end

    item_string = ""
    line_items.each do |item|
      item_string += "items[][id]=#{item[:variant_id]}%26items[][quantity]=#{item[:quantity]}%26items[][selling_plan]=#{item[:selling_plan_id]}%26"
    end
    link = "https://#{@shop.shopify_domain}/cart/clear?return_to=/cart/add?#{item_string}return_to=/checkout"
    checkout = Checkout.new(
      shop: @shop,
      draft_order_id:,
      name: draft_order_name,
      link:,
    )
    checkout.save!
    checkout
  end
end
