# frozen_string_literal: true

FactoryBot.define do
  factory :payment do
    idempotency_key { SecureRandom.hex(16) }
    payment_reference_id { SecureRandom.hex(16) }
    status { "PENDING" }
    order
  end
end
