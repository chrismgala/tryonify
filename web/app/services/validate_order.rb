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
    has_pending_orders?
  end

  def has_pending_orders?
    # Pending order exists for same email and shop
    orders = Order.where(email: @order.email, shop: @order.shop).where("total_outstanding > 0")

    if orders.length.positive?
      @errors << "Existing pending orders: #{orders.map(&:name).join(", ")}"
    end
  end
end
