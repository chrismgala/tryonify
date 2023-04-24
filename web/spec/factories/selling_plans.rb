# frozen_string_literal: true

FactoryBot.define do
  factory :selling_plan do
    shopify_id { "gid://shopify/SellingPlan/#{Faker::Number.number(digits: 10)}" }
    name { "Free Trial" }
  end
end
