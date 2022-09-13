# frozen_string_literal: true

class SellingPlanGroupDestroyJob < ApplicationJob
  def perform(shop_id, selling_plan_group_id)
    shop = Shop.find(shop_id)

    shop.with_shopify_session do
      service = DestroySellingPlanGroup.new(selling_plan_group_id)
      service.call
    end
  end
end