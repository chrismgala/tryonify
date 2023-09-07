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

    trait :with_valid_authorizations do
      shop { association(:shop, authorize_transactions: true) }

      after(:create) do |order|
        create(
          :transaction,
          kind: "authorization",
          authorization_expires_at: 2.days.from_now,
          status: :success,
          order: order,
        )
      end
    end

    trait :with_expiring_authorization do
      shop { association(:shop, authorize_transactions: true) }

      after(:create) do |order|
        create(
          :transaction,
          kind: "authorization",
          authorization_expires_at: 1.hour.from_now,
          status: :success,
          order: order,
        )
      end
    end

    trait :with_expiring_paypal_authorization do
      shop { association(:shop, authorize_transactions: true) }

      after(:create) do |order|
        create(
          :transaction,
          kind: "authorization",
          gateway: "paypal",
          authorization_expires_at: 1.day.ago,
          status: :success,
          order: order,
        )
      end
    end

    trait :with_expired_authorization do
      shop { association(:shop, authorize_transactions: true) }

      after(:create) do |order|
        create(
          :transaction,
          kind: "authorization",
          authorization_expires_at: 1.hour.ago,
          status: :success,
          order: order,
        )
      end
    end

    trait :with_failed_authorization do
      shop { association(:shop, authorize_transactions: true) }

      after(:create) do |order|
        create(
          :transaction,
          kind: "authorization",
          authorization_expires_at: nil,
          status: :failure,
          order: order,
        )
      end
    end

    trait :with_prepaid_card do
      shop { association(:shop) }

      after(:create) do |order|
        create(
          :transaction,
          kind: "sale",
          authorization_expires_at: nil,
          status: :success,
          receipt: '{
            "amount": 100,
            "amount_capturable": 0,
            "amount_received": 100,
            "charges": {
              "data": [
                {
                  "id": "ch_3Nks5QQvX6TsQr9p1N9jZ2R8",
                  "object": "charge",
                  "amount": 100,
                  "payment_method_details": {
                    "card": {
                      "funding": "prepaid",
                    },
                    "type": "card"
                  },
                  "status": "succeeded",
                }
              ],
            },
          }',
          order: order,
        )
      end
    end
  end

  trait :with_return do
    after(:create) do |order|
      create(:return, order_id: order.id, shop_id: order.shop.id)
    end
  end
end
