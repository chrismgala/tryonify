# frozen_string_literal: true

class Order < ApplicationRecord
  validates :shopify_id, :email, :financial_status, presence: true
  validates :shopify_id, uniqueness: true

  belongs_to :shop
  has_many :returns
  has_one :payment

  scope :payment_due, lambda {
                        where('due_date < ?', DateTime.current)
                          .where(financial_status: %w[PARTIALLY_PAID PENDING])
                          .where(closed_at: nil)
                      }
  scope :pending, lambda {
                    where('DATE(due_date) > DATE(?)', DateTime.current)
                      .where(financial_status: %w[PARTIALLY_PAID PENDING]).where(closed_at: nil)
                  }
  scope :pending_returns, -> { includes(:returns).where(returns: { active: true }) }
  scope :failed_payments, lambda {
                            where(financial_status: %w[PARTIALLY_PAID PENDING])
                              .where(closed_at: nil)
                              .joins(:payment).where(payment: { status: 'ERROR' })
                          }
end
