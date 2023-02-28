# frozen_string_literal: true

# Update an order from Shopify ID
class CreateOrUpdateOrder < ApplicationService
  attr_accessor :error

  def initialize(order_instance)
    super()
    @order_instance = order_instance
  end

  def call
    return unless has_selling_plan?

    @order = Order.find_by(shopify_id: @order_instance[:shopify_id])

    if @order
      @order.line_items.destroy_all
      @order&.shipping_address&.destroy
      @order.update(@order_instance)
    else
      @order = Order.create!(@order_instance)

      # Add TryOnify tag to order
      tag_order

      # Check for fraud or invalid orders
      validate

      # Update integrations
      send_notifications
    end
  rescue StandardError => e
    Rails.logger.error("[CreateOrUpdateOrder Failed]: #{e}")
    @error = e
    raise @error
  end

  private

  def has_selling_plan?
    @order_instance[:line_items_attributes].find { |line_item| !line_item[:selling_plan_id].nil? }
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
