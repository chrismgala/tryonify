# frozen_string_literal: true

class Transaction < ApplicationRecord
  belongs_to :order
  belongs_to :parent_transaction, class_name: "Transaction", optional: true

  enum :kind, [:authorization, :void, :capture, :change, :refund, :sale, :suggested_refund]
  enum :status, [:awaiting_response, :error, :failure, :pending, :success, :unknown]

  # after_create :retry_transaction, if: :retryable?
  after_create_commit :cancel_order, if: :invalid_authorization?

  scope :successful_authorizations, -> { where(kind: :authorization, error: nil, voided: false, status: :success) }
  scope :failed_authorizations, -> { where(kind: :authorization).where(error: INVALID_TRANSACTION_ERRORS) }
  scope :reauthorization_required, -> {
                                     successful_authorizations
                                       .where(parent_transaction_id: nil)
                                       .where("authorization_expires_at < ?", 12.hours.from_now)
                                   }
  INVALID_TRANSACTION_ERRORS = ["CARD_DECLINED", "EXPIRED_CARD", "INVALID_AMOUNT", "PICK_UP_CARD"].freeze
  RETRY_TRANSACTION_ERRORS = ["PROCESSING_ERROR", "PAYMENT_METHOD_UNAVAILABLE", "GENERIC_ERROR", "CONFIG_ERROR"].freeze

  private

  def invalid_authorization?
    return true if kind == "authorization" && INVALID_TRANSACTION_ERRORS.include?(error)
    return true if kind == "authorization" && gateway == "paypal" && status == "failure"

    false
  end

  def retry_transaction
  end

  def cancel_order
    order.cancel
  end

  def retryable?
    RETRY_TRANSACTION_ERRORS.include?(error)
  end

  def invalid?
    INVALID_TRANSACTION_ERRORS.include?(error)
  end
end
