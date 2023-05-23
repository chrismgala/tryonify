# frozen_string_literal: true

class Order < ApplicationRecord
  include PgSearch::Model

  validates :shopify_id, :email, :financial_status, presence: true
  # validates :due_date, presence: true, if: -> { cancelled_at.nil? }
  validates :shopify_id, uniqueness: true
  validate :has_selling_plan?, on: :create

  belongs_to :shop
  has_many :line_items
  has_many :returns
  has_many :transactions
  has_many :payments
  has_one :shipping_address

  scope :payment_due, lambda {
                        where("due_date < ?", Time.current)
                          .where(fully_paid: false)
                          .where(cancelled_at: nil)
                          .where(ignored_at: nil)
                      }
  scope :pending, lambda {
                    where("due_date > ?", Time.current)
                      .where(fully_paid: false)
                      .where(cancelled_at: nil)
                      .where(ignored_at: nil)
                  }
  scope :pending_returns, -> { includes(:returns).where(returns: { active: true }) }
  scope :failed_payments, lambda {
                            includes(:transactions)
                              .where(fully_paid: false)
                              .where(cancelled_at: nil)
                              .where("due_date < ?", Time.current)
                              .where(transactions: { kind: :sale, status: :failure })
                          }

  accepts_nested_attributes_for :line_items, :shipping_address

  attribute :calculated_due_date, :datetime

  pg_search_scope :search_by_name, against: :name, using: { tsearch: { prefix: true } }

  pg_search_scope :address_search,
    associated_against: {
      shipping_address: [:city, :address1, :address2, :zip],
    },
    using: :trigram

  def has_selling_plan?
    unless line_items.find { |x| !x.selling_plan_id.nil? }.present?
      errors.add(:base, "Order must have a selling plan")
    end
  end

  def pending?
    return false if calculated_due_date.before?(DateTime.current)
    return false if cancelled_at
    return false if fully_paid

    true
  end

  def latest_authorization
    transactions.successful_authorizations
      .order(authorization_expires_at: :desc)
      .first
  end

  def authorized?
    transactions.successful_authorizations.any?
  end

  def authorization_invalid?
    transactions.failed_authorizations.any?
  end

  def unfulfilled?
    fulfillment_status == "UNFULFILLED"
  end

  def should_reauthorize?
    return false unless shop.authorize_transactions
    return false if transactions.failed_authorizations.any?

    # If the order is pending
    if pending?
      # And it has transactions that require reauthorization
      if transactions.reauthorization_required.any?
        # If the authorization is from PayPal, wait until the next day to reauthorize
        if latest_authorization.gateway == "paypal" && latest_authorization.authorization_expires_at + 1.day < Time.current
          true
        elsif latest_authorization.gateway != "paypal"
          true
        end
      end
    end
  end

  def voided?
    transactions.where(kind: :void).any?
  end

  def calculated_due_date
    latest_return = returns.where(active: true).order(created_at: :desc).first

    # If return due date comes after order due date, use the return due date
    if latest_return
      return_due_date = latest_return.created_at + shop.return_period if latest_return
      return return_due_date if return_due_date&.after?(due_date)
    end

    due_date
  end

  def cancel
    OrderCancelJob.perform_later(id) if pending? && unfulfilled?
  end

  def ignore!
    update!(ignored_at: Time.current)
  end

  def line_items_attributes=(*attrs)
    self.line_items = []
    super(*attrs)
  end

  class << self
    def search(query)
      if query.present?
        search_by_name(query)
      else
        order(shopify_created_at: :desc)
      end
    end
  end
end
