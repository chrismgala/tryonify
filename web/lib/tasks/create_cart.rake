# frozen_string_literal: true

desc "Create cart"
task create_cart: :environment do |_task, _args|
  puts "Creating cart..."

  shop = Shop.find(19)

  shop.with_shopify_session do
    unless shop.storefront_access_token
      response = StorefrontAccessTokenCreate.call
      access_token = response.body.dig("data", "delegateAccessTokenCreate", "delegateAccessToken", "accessToken")

      if access_token
        shop.storefront_access_token = access_token
        return unless shop.save!
      end
    end

    line_items = [
      {
        merchandiseId: "gid://shopify/ProductVariant/6940131098667",
        quantity: 1,
        sellingPlanId: "gid://shopify/SellingPlan/799735851",
      },
    ]

    response = CartCreate.call(line_items: line_items)
  end

  puts "done."
end
