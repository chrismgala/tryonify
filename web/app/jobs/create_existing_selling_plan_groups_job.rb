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

      if shop.selling_plans.any?
        selling_plans = shop.selling_plans.pluck(:shopify_id)
        attributes = {
          key: "sellingPlans",
          namespace: "$app:settings",
          ownerId: shop.shopify_id,
          type: "json",
          value: selling_plans.to_json,
        }
        Shopify::Metafields::Create.call([attributes])
      end
    end
  end
end
