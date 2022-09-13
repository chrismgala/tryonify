# frozen_string_literal: true

class SellingPlanGroupUpdateJob < ApplicationJob
  def perform(shop_id, id)
    shop = Shop.find(shop_id)
    selling_plan_group = SellingPlanGroup.find(id)

    shop.with_shopify_session do
      sellingPlanGroupService = UpdateSellingPlanGroup.new(selling_plan_group)
      sellingPlanGroupService.call
    end
  end
end