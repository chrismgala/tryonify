# frozen_string_literal: true

# Update an order from Shopify ID
class CreateOrUpdateOrder
  class InvalidRequest < StandardError; end

  attr_accessor :order, :error

  def initialize(shop_id:, order_id:)
    @shop_id = shop_id
    @order_id = order_id
    @order = nil
  end

  def call
    service = if @order_id.to_s.starts_with?("gid://")
      FetchOrder.new(@order_id)
    else
      FetchOrder.new("gid://shopify/Order/#{@order_id}")
    end
    service.call

    raise service.error and return if service.error

    @order = service.order

    existing_order = Order.find_by(shopify_id: @order_id)

    order_attributes = {
      shopify_id: @order.dig("legacyResourceId"),
      shopify_created_at: @order.dig("createdAt"),
      shopify_updated_at: @order.dig("updatedAt"),
      name: @order.dig("name"),
      due_date: @order.dig("paymentTerms", "paymentSchedules", "edges", 0, "node", "dueAt"),
      closed_at: @order.dig("closedAt"),
      cancelled_at: @order.dig("cancelledAt"),
      financial_status: @order["displayFinancialStatus"],
      fulfillment_status: @order["displayFulfillmentStatus"],
      email: @order.dig("customer", "email"),
      mandate_id: @order.dig("paymentCollectionDetails", "vaultedPaymentMethods", 0, "id"),
      fully_paid: @order.dig("fullyPaid"),
      total_outstanding: @order.dig("totalOutstandingSet", "shopMoney", "amount"),
    }

    if existing_order
      existing_order.update(order_attributes)
    elsif has_selling_plan?(@order)
      # Tag order as TryOnify
      tag_order

      order_attributes[:shop_id] = @shop_id
      new_order = Order.create!(order_attributes)

      if new_order
        shop = Shop.find(@shop_id)
        KlaviyoEvent.new(shop).call(
          event: "TryOnify Order Created",
          email: @order.dig("customer", "email"),
          properties: {
            "order_id": @order.dig("name"),
            "amount": @order.dig("totalPriceSet", "shopMoney", "amount"),
          }
        )
      end
    end
  rescue StandardError => e
    Rails.logger.error("[CreateOrUpdateOrder Failed]: #{e}")
    @error = e
    raise @error
  end

  # Page through line items looking for selling plan
  def has_selling_plan?(order)
    line_items = order.dig("lineItems", "edges")
    selling_plan_ids = line_items.select { |x| x.dig("node", "sellingPlan", "sellingPlanId") }
      .map { |x| x.dig("node", "sellingPlan", "sellingPlanId") }

    if selling_plan_ids.length.positive? && SellingPlan.where(shopify_id: selling_plan_ids).any?
      true
    elsif order.dig("lineItems", "pageInfo", "hasNextPage")
      service = FetchOrder.new(order.dig("id"),
        order.dig("lineItems", "pageInfo", "endCursor"))
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

  def tag_order
    service = UpdateOrderTag.new(@shop_id, @order)
    service.call
  end
end
