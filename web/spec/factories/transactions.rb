# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    shopify_id { "gid://shopify/OrderTransaction/#{Faker::Number.number(digits: 10)}" }
    amount { Faker::Number.decimal(l_digits: 2) }
    kind { "authorization" }
    order
  end
end
