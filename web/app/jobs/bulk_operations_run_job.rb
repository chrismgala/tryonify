# frozen_string_literal: true

class BulkOperationsRunJob < ApplicationJob
  def perform(shop)
    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    shop.with_shopify_session do
      Shopify::Orders::BulkFetch.call
    end
  end
end