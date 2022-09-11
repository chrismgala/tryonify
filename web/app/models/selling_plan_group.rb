# frozen_string_literal: true

class SellingPlanGroup < ApplicationRecord
  validates :name, presence: true
  validates_associated :selling_plan

  has_one :selling_plan, dependent: :destroy
  belongs_to :shop

  accepts_nested_attributes_for :selling_plan

  def description
    self[:description] || ''
  end
end
