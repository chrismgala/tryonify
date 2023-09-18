# frozen_string_literal: true

class OrderUpdate < ApplicationService
  attr_accessor :error

  def initialize(order_attributes:, order: nil)
    super()
    @order_attributes = order_attributes
    @order = order
  end

  def call
    @order = Order.find_by!(shopify_id: @order_attributes[:shopify_id]) unless @order
    @order_attributes = @order_attributes.except(:email) if @order_attributes[:email].blank?

    update_associated(:line_items)
    update_associated(:transactions)

    @order.update(@order_attributes)
  end

  private

  def update_associated(association_name)
    associated = @order.public_send association_name
    nested_attribute_name = "#{association_name}_attributes".to_sym

    return unless @order_attributes[nested_attribute_name]

    associated.each do |item|
      item_attribute = @order_attributes[nested_attribute_name].find {|x| x[:shopify_id] == item.shopify_id }

      if item_attribute
        item_attribute[:id] = item.id
      else
        @order_attributes[nested_attribute_name] << { id: item.id, _destroy: true }
      end
    end
  end
end
