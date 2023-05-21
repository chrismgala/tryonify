# frozen_string_literal: true

class Transaction < ApplicationRecord
  has_one :payment
  belongs_to :order
  belongs_to :parent_transaction, class_name: "Transaction", optional: true

  enum :kind, [:authorization, :void, :capture, :change, :refund, :sale, :suggested_refund]
  enum :status, [:awaiting_response, :error, :failure, :pending, :success, :unknown]

  # after_create :retry_transaction, if: :retryable?
  after_create_commit :cancel_order, if: :invalid_authorization?

  scope :successful_authorizations, -> { where(kind: :authorization, error: nil, voided: false, status: :success) }
  scope :failed_authorizations, -> { where(kind: :authorization).where(status: :failure) }
  scope :reauthorization_required, -> {
                                     successful_authorizations
                                       .where(parent_transaction_id: nil)
                                       .where("authorization_expires_at < ?", 6.hours.from_now)
                                   }
  INVALID_TRANSACTION_ERRORS = ["CARD_DECLINED", "EXPIRED_CARD", "INVALID_AMOUNT", "PICK_UP_CARD"].freeze
  RETRY_TRANSACTION_ERRORS = ["PROCESSING_ERROR", "PAYMENT_METHOD_UNAVAILABLE", "GENERIC_ERROR", "CONFIG_ERROR"].freeze

  private

  def invalid_authorization?
    kind == "authorization" && status == "failure"
  end

  def reauthorization?
    order.transactions.where(kind: :authorization).count > 1
  end

  def retry_transaction
  end

  def cancel_order
    order.cancel unless reauthorization?
  end

  def retryable?
    RETRY_TRANSACTION_ERRORS.include?(error)
  end

  def invalid?
    INVALID_TRANSACTION_ERRORS.include?(error)
  end
end
