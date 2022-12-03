# frozen_string_literal: true

class Order < ApplicationRecord
  validates :shopify_id, :email, :financial_status, presence: true
  validates :shopify_id, uniqueness: true

  belongs_to :shop
  has_many :returns
  has_one :payment

  scope :payment_due, lambda {
                        where("due_date < ?", DateTime.current)
                          .where("total_outstanding > 0")
                          .where(closed_at: nil)
                      }
  scope :pending, lambda {
                    where("DATE(due_date) > DATE(?)", DateTime.current)
                      .where("total_outstanding > 0").where(closed_at: nil)
                  }
  scope :pending_returns, -> { includes(:returns).where(returns: { active: true }) }
  scope :failed_payments, lambda {
                            where("total_outstanding > 0")
                              .where(closed_at: nil)
                              .joins(:payment).where(payment: { status: "ERROR" })
                          }

  attribute :calculated_due_date, :datetime

  def calculated_due_date
    latest_return = returns.where(active: true).order(created_at: :desc).first

    # If return due date comes after order due date, use the return due date
    if latest_return
      return_due_date = latest_return.created_at + shop.return_period if latest_return
      return return_due_date if return_due_date&.after?(due_date)
    end

    due_date
  end
end
