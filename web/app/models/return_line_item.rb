# frozen_string_literal: true

class ReturnLineItem < ApplicationRecord
  belongs_to :return
  belongs_to :line_item

  validates :quantity, presence: true, numericality: { greater_than: 0 }

  after_create_commit :update_due_date, if: :trial_return?

  # Only recalculate on the first return
  def trial_return?
    line_item.selling_plan_id.present?
  end

  def update_due_date
    order.update_due_date
  end
end