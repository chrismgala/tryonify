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

    @order_attributes[:max_due_date] = max_due_date
    @order = Order.create!(@order_attributes)

    # Fetch order transactions
    fetch_transactions
    # Add TryOnify tag to order
    tag_order
    # Check for fraud or invalid orders
    valid?
    # Authorize order
    authorize if @order.shop.authorize_transactions
    # Update integrations
    send_notifications

    @order
  rescue ActiveRecord::RecordInvalid => err
    Rails.logger.error("[OrderCreate Failed name=#{@order_attributes[:name]}]: #{err.message}")
  rescue => err
    Rails.logger.error("[OrderCreate Failed]: #{err.message}")
    raise err
  end

  private

  def has_selling_plan?
    @order_attributes[:line_items_attributes].find { |line_item| !line_item[:selling_plan_id].nil? }
  end

  def max_due_date
    line_item = @order_attributes[:line_items_attributes].find { |line_item| !line_item[:selling_plan_id].nil? }
    selling_plan = SellingPlan.find(line_item[:selling_plan_id]) if line_item.present?
  
    return nil unless selling_plan.present?

    shop = Shop.find(@order_attributes[:shop_id])

    return nil unless shop.present?

    @order_attributes[:shopify_created_at] + selling_plan.trial_days.days + shop.return_period.days
  end

  def fetch_transactions
    OrderTransactionsUpdate.call(@order)
  end

  def tag_order
    service = UpdateOrderTag.new(@order.shopify_id, @order.tags)
    service.call
  end

  def valid?
    errors = ValidateOrder.call(@order)
    errors.length.zero?
  end

  def authorize
    OrderAuthorizeJob.perform_later(@order.id)
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
