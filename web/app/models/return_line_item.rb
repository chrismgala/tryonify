# frozen_string_literal: true

class ReturnLineItem < ApplicationRecord
  belongs_to :return
  belongs_to :line_item

  validates :quantity, presence: true, numericality: { greater_than: 0 }

  after_create_commit :create_tasks, if: :trial_return?

  # Only recalculate on the first return
  def trial_return?
    line_item.selling_plan_id.present?
  end

  def update_due_date
    self.return.order.update_due_date
  end

  private

  def create_tasks
    update_due_date

    broadcast_update_to line_item
  end
end