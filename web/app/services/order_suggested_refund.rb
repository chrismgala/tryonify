# frozen_string_literal: true

class OrderSuggestedRefund < ApplicationService
  def initialize(order)
    super()
    @order = order
    @session = ShopifyAPI::Context.active_session
  end

  def call
  end

  private

  def fetch_suggested_refund
  end
end
