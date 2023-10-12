# frozen_string_literal: true

FactoryBot.define do
  factory :return_line_item do
    shopify_id { Faker::Number.number(digits: 10) }
    quantity { 1 }
  end
end