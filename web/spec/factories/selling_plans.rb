# frozen_string_literal: true

FactoryBot.define do
  factory :selling_plan do
    shopify_id { "gid://shopify/SellingPlan/#{Faker::Number.number(digits: 10)}" }
    name { "Free Trial" }
    selling_plan_group
  end
end
