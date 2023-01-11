# frozen_string_literal: true

# Update an order from Shopify ID
class CreateOrUpdateOrder
  class InvalidRequest < StandardError; end

  attr_accessor :order, :error

  def initialize(order_attributes, tags = [])
    @order_attributes = order_attributes
    @tags = tags
    @order = nil
  end

  def call
    puts @order_attributes[:shopify_id]
    @order = Order.find_by(shopify_id: @order_attributes[:shopify_id])

    update_order and return if @order

    create_order
  rescue StandardError => e
    Rails.logger.error("[CreateOrUpdateOrder Failed]: #{e}")
    @error = e
    raise @error
  end

  private

  def create_order
    @order = Order.create!(@order_attributes)

    tag_order
    validator = ValidateOrder.new(@order)
    validator.call

    if @order
      KlaviyoEvent.new(@order.shop).call(
        event: "TryOnify Order Created",
        email: @order.email,
        properties: {
          "order_id": @order.name,
        }
      )
    end
  end

  def update_order
    @order.update(@order_attributes)
  end

  def tag_order
    service = UpdateOrderTag.new("gid://shopify/Order/#{@order.shopify_id}", @tags)
    service.call
  end
end
