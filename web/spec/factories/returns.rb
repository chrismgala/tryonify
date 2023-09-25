# frozen_string_literal: true

FactoryBot.define do
  factory :return do
    shopify_id { Faker::Number.number(digits: 10) }
    status { :open }
    quantity { 1 }
    line_item
    order
  end
end
