# frozen_string_literal: true

class Payment < ApplicationRecord
  validates :payment_reference_id, :idempotency_key, :status, presence: true
  validates :payment_reference_id, :idempotency_key, uniqueness: true

  belongs_to :order
end
