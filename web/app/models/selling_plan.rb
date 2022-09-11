# frozen_string_literal: true

class SellingPlan < ApplicationRecord
  validates :name, :prepay, :trial_days, presence: true
  validates :trial_days, numericality: { only_integer: true, less_than_or_equal_to: 60 }

  belongs_to :selling_plan_group

  def description
    self[:description] || ''
  end
end
