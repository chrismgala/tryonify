# frozen_string_literal: true

class OrderUpdate < ApplicationService
  attr_accessor :error

  def initialize(order_attributes:, order: nil)
    super()
    @order_attributes = order_attributes
    @order = order
  end

  def call
    @order = Order.find_by!(shopify_id: order_attributes[:shopify_id]) unless @order

    Order.transaction do
      @order.line_items.destroy_all
      @order.shipping_address&.destroy
      @order.update(@order_attributes)
    end
  end
end
