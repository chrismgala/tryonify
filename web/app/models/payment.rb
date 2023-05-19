# frozen_string_literal: true

class Payment < ApplicationRecord
  validates :idempotency_key, :status, presence: true
  validates :payment_reference_id, :idempotency_key, uniqueness: true

  belongs_to :order
  belongs_to :parent_transaction, class_name: :Transaction, optional: true
end
