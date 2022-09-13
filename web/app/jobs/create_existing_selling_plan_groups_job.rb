# frozen_string_literal: true

class CreateExistingSellingPlanGroupsJob < ApplicationJob
  def perform(shop_id, cursor = nil)
    shop = Shop.find(shop_id)
    
    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    shop.with_shopify_session do
      service = CreateExistingSellingPlanGroups.new(shop, cursor)
      service.call
    end
  end
end