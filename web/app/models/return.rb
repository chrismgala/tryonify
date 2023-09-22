# frozen_string_literal: true

class Return < ApplicationRecord
  validates :shopify_id, presence: true, uniqueness: true

  belongs_to :shop
  belongs_to :order, counter_cache: true
  belongs_to :line_item

  enum :status, [:canceled, :closed, :declined, :open, :requested]

  after_create_commit :update_order, if: :first_return?

  # Only recalculate on the first return
  def first_return?
    Return.where(order_id: order_id).count == 1
  end

  def update_order
    order.update_due_date
  end
end