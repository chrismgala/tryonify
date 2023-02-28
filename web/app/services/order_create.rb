# frozen_string_literal: true

class OrderCreate < ApplicationService
  attr_accessor :error

  def initialize(order_attributes)
    super()
    @order_attributes = order_attributes
    @order = nil
  end

  def call
    return unless has_selling_plan?

    puts @order_attributes.inspect
    @order = Order.create!(@order_attributes)

    # Add TryOnify tag to order
    tag_order
    # Check for fraud or invalid orders
    validate
    # Update integrations
    send_notifications

    @order
  end

  private

  def has_selling_plan?
    @order_attributes[:line_items_attributes].find { |line_item| !line_item[:selling_plan_id].nil? }
  end

  def tag_order
    service = UpdateOrderTag.new(@order.shopify_id, @order.tags)
    service.call
  end

  def validate
    ValidateOrderJob.perform_later(@order.id)
  end

  def send_notifications
    KlaviyoEvent.new(@order.shop).call(
      event: "TryOnify Order Created",
      email: @order.email,
      properties: {
        "order_id": @order.name,
      }
    )
  end
end
