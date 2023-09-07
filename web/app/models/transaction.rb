# frozen_string_literal: true

class Transaction < ApplicationRecord
  has_one :payment
  belongs_to :order
  belongs_to :parent_transaction, class_name: "Transaction", optional: true

  enum :kind, [:authorization, :void, :capture, :change, :refund, :sale, :suggested_refund]
  enum :status, [:awaiting_response, :error, :failure, :pending, :success, :unknown]

  # after_create :retry_transaction, if: :retryable?
  after_create_commit :cancel_order, if: :should_cancel?

  scope :successful_authorizations, -> { where(kind: :authorization, error: nil, voided: false, status: :success) }
  scope :failed_authorizations, -> { where(kind: :authorization).where(status: :failure) }
  scope :reauthorization_required, -> {
                                     successful_authorizations
                                       .where(parent_transaction_id: nil)
                                       .where("authorization_expires_at < ?", 6.hours.from_now)
                                   }
  INVALID_TRANSACTION_ERRORS = ["CARD_DECLINED", "EXPIRED_CARD", "INVALID_AMOUNT", "PICK_UP_CARD"].freeze
  RETRY_TRANSACTION_ERRORS = ["PROCESSING_ERROR", "PAYMENT_METHOD_UNAVAILABLE", "GENERIC_ERROR", "CONFIG_ERROR"].freeze

  def invalid_authorization?
    kind == "authorization" && status == "failure"
  end

  def prepaid_card?
    return false unless gateway == 'shopify_payments'

    if receipt
      funding = JSON.parse(receipt).dig('charges', 'data', 0, 'payment_method_details', 'card', 'funding')
      funding == 'prepaid'
    else
      false
    end
  end

  def reauthorization?
    order.transactions.where(kind: :authorization).count > 1
  end

  def should_cancel?
    if order.shop.cancel_prepaid_cards && prepaid_card?
      return true
    end

    if order.shop.authorize_transactions && invalid_authorization?
      return true
    end

    false
  end

  private

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
