# frozen_string_literal: true

class OrderCancel < ApplicationService
  def initialize(order:, refund: true, reason:)
    super()
    @order = order
    @refund = refund
    @reason = reason
    @session = ShopifyAPI::Context.active_session
  end

  def call
    return unless @order

    # Cancel order
    puts cancel_order
    # Update integrations
    send_notifications
  end

  private

  def cancel_order
    shopify_order = ShopifyAPI::Order.find(id: @order.shopify_id.split("/").pop, session: @session)
    shopify_order.cancel(session: @session)
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
