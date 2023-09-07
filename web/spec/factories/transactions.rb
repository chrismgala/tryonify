# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    shopify_id { "gid://shopify/OrderTransaction/#{Faker::Number.number(digits: 10)}" }
    amount { Faker::Number.decimal(l_digits: 2) }
    kind { "authorization" }
    order
    gateway { "shopify_payments" }

    trait :with_prepaid_card do
      receipt {
        {
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
        }.to_json
      }
    end
  end
end
