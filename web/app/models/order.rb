# frozen_string_literal: true

class Order < ApplicationRecord
  validates :shopify_id, :email, presence: true
  validates :shopify_id, uniqueness: true

  belongs_to :shop
  has_many :returns

  scope :payment_due, -> { where('due_date < ?', Date.today) }
  scope :pending, -> { where(['due_date > ? and status = ?', Date.today, 'PENDING']) }
  scope :pending_returns, -> { joins(:returns).where('returns.active = true') }
end