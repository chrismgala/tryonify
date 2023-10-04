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
    
    update_associated(target: @order, attributes: @order_attributes, association_name: :line_items)
    update_associated(target: @order, attributes: @order_attributes, association_name: :transactions)
    update_associated(target: @order, attributes: @order_attributes, association_name: :returns)

    @order.returns.each do |return_item|
      associated_attributes = @order_attributes[:returns_attributes].find {|x| x[:shopify_id] == return_item.shopify_id }
      update_associated(target: return_item, attributes: associated_attributes || {}, association_name: :return_line_items)
    end

    @order.update!(@order_attributes)
  end

  private

  def update_associated(target:, attributes:, association_name:)
    associated = target.public_send association_name
    nested_attribute_name = "#{association_name}_attributes".to_sym

    return unless attributes[nested_attribute_name]

    associated.each do |item|
      item_attribute = attributes[nested_attribute_name].find {|x| x[:shopify_id] == item.shopify_id }

      if item_attribute
        item_attribute[:id] = item.id
      else
        attributes[nested_attribute_name] << { id: item.id, _destroy: true }
      end
    end
  end
end
