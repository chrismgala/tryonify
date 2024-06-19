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
    Shopify::Orders::Cancel.call(
      order_id: @order.shopify_id,
      refund: @refund,
      restock: true,
      reason: "DECLINED",
      staff_note: "Cancelled by TryOnify"
    )
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
