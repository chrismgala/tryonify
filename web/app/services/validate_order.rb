# frozen_string_literal: true

class ValidateOrder
  def initialize(order)
    @order = order
    @errors = []
  end

  def call
    validate

    unless @errors.length.zero?
      if @order.shop.slack_token
        service = SlackMessage.new(@order.shop)

        message = "*Invalid Order #{@order.name}*\n\n"

        @errors.each do |error|
          message += "- #{error}\n"
        end

        service.send(message)
      end
    end
  end

  private

  def validate
    # Customer already has an active trial
    has_same_email?
    has_same_ip_address?
    has_similar_address?
  end

  def has_same_email?
    # Pending order exists for same email and shop
    orders = Order.where(email: @order.email, shop: @order.shop)
      .where("total_outstanding > 0")
      .where(fully_paid: false)
      .where.not(id: @order.id)

    if orders.length.positive?
      @errors << "Pending orders with same e-mail: #{orders.map(&:name).join(", ")}"
    end
  end

  def has_same_ip_address?
    orders = Order.where(shop: @order.shop, ip_address: @order.ip_address)
      .where("total_outstanding > 0")
      .where(fully_paid: false)
      .where.not(id: @order.id)

    if orders.length.positive?
      @errors << "Pending orders with same IP address: #{orders.map(&:name).join(", ")}"
    end
  end

  def has_similar_address?
    shipping_address = @order.shipping_address

    orders = Order.where(shop: @order.shop)
      .where("total_outstanding > 0")
      .where(fully_paid: false)
      .where.not(id: @order.id)
      .address_search("#{shipping_address.city} #{shipping_address.address1} #{shipping_address.address2} #{shipping_address.zip}")

    if orders.length.positive?
      @errors << "Pending orders with similar address: #{orders.map(&:name).join(", ")}"
    end
  end
end
