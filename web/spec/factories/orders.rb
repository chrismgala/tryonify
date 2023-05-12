# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    shopify_id { "gid://shopify/Order/#{Faker::Number.number(digits: 10)}" }
    due_date { Time.now + 1.day }
    name { Faker::Number.number(digits: 4) }
    financial_status { "PARTIALLY_PAID" }
    mandate_id { "gid://shopify/PaymentMandate/#{Faker::Number.number(digits: 10)}" }
    email { Faker::Internet.email }
    shopify_created_at { Time.new }
    shopify_updated_at { Time.new }
    fulfillment_status { "UNFULFILLED" }
    fully_paid { false }
    total_outstanding { 231.07 }
    shop
    line_items { [association(:line_item, order: instance)] }

    trait :without_selling_plan do
      after(:build) do |order|
        build(:line_item, order: order, selling_plan: nil)
      end
    end

    trait :with_expiring_authorization do
      shop { association(:shop, authorize_transactions: true) }

      after(:create) do |order|
        create(:transaction, kind: "authorization", authorization_expires_at: 1.hour.from_now, status: :success,
          order: order)
      end
    end
  end

  trait :with_return do
    after(:create) do |order|
      create(:return, order_id: order.id, shop_id: order.shop.id)
    end
  end
end
