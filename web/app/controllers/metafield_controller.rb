# frozen_string_literal: true

class MetafieldController < ApplicationController
  def show
    gid_string = "gid://shopify/Metafield/#{params[:shopify_id]}"
    metafield = Metafield.find_by(shopify_id: gid_string)

    selling_plan_group = SellingPlanGroup.find_by(shop_id: metafield.shop_id)

    render(json: { message: "Metafield not found" }) && return unless metafield
    render(json: { message: "Selling plan group not found" }) && return unless selling_plan_group

    render(json: {
      data: {
        metafield: {
          key: metafield.key,
          value: metafield.value,
        },
        selling_plan_group: {
          shopify_id: selling_plan_group.shopify_id,
        }
      }
    })
  end
end