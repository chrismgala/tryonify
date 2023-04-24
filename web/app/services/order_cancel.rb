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
  end

  private

  def cancel_order
    suggested_refund = OrderSuggestedRefund.call(@order) if @refund

    shopify_order = ShopifyAPI::Order.find(id: @order.shopify_id.split("/").pop, session: @session)
    shopify_order.cancel(amount: suggested_refund || nil, session: @session)
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
