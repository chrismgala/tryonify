# frozen_string_literal: true

class OrderCancel < ApplicationService
  def initialize(order:, refund: true)
    super()
    @order = order
    @refund = refund
    @session = ShopifyAPI::Context.active_session
  end

  def call
    return unless @order

    # Cancel order
    send_notifications if cancel_order
  rescue StandardError => e
    Rails.logger.error("[OrderCancel Failed]: #{e.message}")
    raise e
  end

  private

  def cancel_order
    suggested_refund = OrderSuggestedRefund.call(@order) if @refund

    shopify_order = ShopifyAPI::Order.find(id: @order.shopify_id.split("/").pop, session: @session)
    refund = {
      note: "Cancelled by TryOnify",
      refund_line_items: suggested_refund&.body&.dig("data", "order", "suggestedRefund", "refundLineItems")&.map do |refund_line_item|
        {
          line_item_id: refund_line_item.dig("lineItem", "id")&.split("/")&.pop,
          quantity: refund_line_item["quantity"],
          restock_type: "cancel",
          location_id: refund_line_item.dig("location", "id")&.split("/")&.pop,
        }
      end,
      transactions: suggested_refund&.body&.dig("data", "order", "suggestedRefund", "suggestedTransactions")&.map do |suggested_transaction|
        {
          parent_id: suggested_transaction.dig("parentTransaction", "id")&.split("/")&.pop,
          amount: suggested_transaction.dig("amountSet", "shopMoney", "amount"),
          kind: "refund",
          gateway: suggested_transaction["gateway"],
        }
      end
    }
    shopify_order.cancel(refund: refund || nil, email: true, session: @session)
  end

  def send_notifications
    KlaviyoEvent.new(@order.shop).call(
      event: "TryOnify Order Cancelled",
      email: @order.email,
      properties: {
        "order_id": @order.name,
      }
    )
  end
end
