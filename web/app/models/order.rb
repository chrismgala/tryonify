# frozen_string_literal: true

class Order < ApplicationRecord
  validates :email, :financial_status, presence: true
  validates :shopify_id, uniqueness: true

  belongs_to :shop
  has_many :returns
  has_one :payment

  scope :payment_due, -> { where(['due_date < ? and financial_status = ?', Date.today, 'PENDING']) }
  scope :pending, -> { where(['due_date > ? and financial_status = ?', Date.today, 'PENDING']) }
  scope :pending_returns, -> { joins(:returns).where('returns.active = true') }
end
