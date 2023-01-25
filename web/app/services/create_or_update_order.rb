# frozen_string_literal: true

# Update an order from Shopify ID
class CreateOrUpdateOrder
  class InvalidRequest < StandardError; end

  attr_accessor :order, :error

  def initialize(order_attributes, line_item_attributes, shipping_address, tags = [])
    @order_attributes = order_attributes
    @line_item_attributes = line_item_attributes
    @shipping_address = shipping_address
    @tags = tags
    @order = nil
  end

  def call
    @order = Order.find_by(shopify_id: @order_attributes[:shopify_id])

    update_order and return if @order

    create_order
    create_or_update_line_items
  rescue StandardError => e
    Rails.logger.error("[CreateOrUpdateOrder Failed]: #{e}")
    @error = e
    raise @error
  end

  private

  def create_order
    @order = Order.create!(@order_attributes)

    shipping_address = ShippingAddress.new(@shipping_address)
    shipping_address.order = @order
    shipping_address.save!

    tag_order

    ValidateOrderJob.perform_later(@order.id)

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

  def create_or_update_line_items
    @line_item_attributes.each do |item|
      line_item = LineItem.find_or_create_by!(shopify_id: item[:shopify_id]) do |created_line_item|
        created_line_item.order_id = @order.id
        created_line_item.selling_plan_id = item[:selling_plan_id]
      end

      line_item.title = item[:title]
      line_item.variant_title = item[:variant_title]
      line_item.image_url = item[:image_url]
      line_item.quantity = item[:quantity]
      line_item.unfulfilled_quantity = item[:unfulfilled_quantity]
      line_item.restockable = item[:restockable]

      line_item.save!
    end
  end

  def tag_order
    service = UpdateOrderTag.new("gid://shopify/Order/#{@order.shopify_id}", @tags)
    service.call
  end
end
