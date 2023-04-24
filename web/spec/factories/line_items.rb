# frozen_string_literal: true

FactoryBot.define do
  factory :line_item do
    shopify_id { "gid://shopify/LineItem/#{Faker::Number.number(digits: 10)}" }
    title { Faker::Commerce.product_name }
  end
end
