# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    shopify_id { "gid://shopify/Order/#{Faker::Number.number(digits: 10)}" }
    due_date { Time.now }
    name { Faker::Number.number(digits: 4) }
    financial_status { "PARTIALLY_PAID" }
    email { Faker::Internet.email }
    shopify_created_at { Time.new }
    shopify_updated_at { Time.new }
    fulfillment_status { "UNFULFILLED" }
    fully_paid { false }
    total_outstanding { 231.07 }
    shop
  end

  trait :with_return do
    after(:create) do |order|
      create(:return, order_id: order.id, shop_id: order.shop.id)
    end
  end
end
