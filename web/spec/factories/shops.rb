# frozen_string_literal: true

FactoryBot.define do
  factory :shop do
    shopify_domain { Faker::Internet.domain_name }
    shopify_token { Faker::Internet.password }
    access_scopes { "write_orders" }
    return_period { 7 }
  end
end
