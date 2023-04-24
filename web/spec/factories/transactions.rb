# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    shopify_id { "gid://shopify/OrderTransaction/#{Faker::Number.number(digits: 10)}" }
  end
end
