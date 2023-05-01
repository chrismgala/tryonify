# frozen_string_literal: true

class ReauthorizeOrders < ApplicationService
  def initialize(shop)
    super()
    @shop = shop
  end

  def call
    reauthorize_orders
  end

  private

  def reauthorize_orders
    @shop.with_shopify_session do
      @shop.orders.pending.find_each do |order|
        OrderAuthorizeJob.perform_later(order.id) if order.should_reauthorize?
      end
    end
  end
end
