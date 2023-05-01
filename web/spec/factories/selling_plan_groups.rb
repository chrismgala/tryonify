# frozen_string_literal: true

FactoryBot.define do
  factory :selling_plan_group do
    shopify_id { "gid://shopify/SellingPlanGroup/#{Faker::Number.number(digits: 10)}" }
    name { "Free Trial" }
    shop { Shop.first || association(:shop) }

    after(:create) do |selling_plan_group|
      FactoryBot.create(:selling_plan, selling_plan_group:)
    end
  end
end
