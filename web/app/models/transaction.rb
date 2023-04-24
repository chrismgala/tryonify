# frozen_string_literal: true

class Transaction < ApplicationRecord
  belongs_to :order
  belongs_to :parent_transaction, class_name: "Transaction", optional: true

  enum :kind, [:authorization, :void, :capture, :change, :refund, :sale, :suggested_refund]

  after_create_commit :void, if: :should_void_authorizations
  # after_create_commit :retry_transaction, if: :retryable?
  after_create_commit :cancel_order # , if: :invalid?

  scope :successful_authorizations, -> { where(kind: :authorization, error: nil, voided: false) }
  scope :reauthorization_required, -> {
                                     successful_authorizations.where("DATE(authorization_expires_at) < DATE(?)", DateTime.current + 12.hours)
                                   }
  INVALID_TRANSACTION_ERRORS = ["CARD_DECLINED", "EXPIRED_CARD", "INVALID_AMOUNT", "PICK_UP_CARD"].freeze
  RETRY_TRANSACTION_ERRORS = ["PROCESSING_ERROR", "PAYMENT_METHOD_UNAVAILABLE", "GENERIC_ERROR", "CONFIG_ERROR"].freeze

  private

  def void
    if kind == "authorization"
      TransactionCreate.call(
        order: order,
        kind: "void",
        parent_transaction_id: shopify_id,
      )
    end
  end

  def should_void_authorizations
    order&.shop&.void_authorizations
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
