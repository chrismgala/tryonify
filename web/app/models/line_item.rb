# frozen_string_literal: true

class LineItem < ApplicationRecord
  validates :shopify_id, presence: true
  validates :shopify_id, uniqueness: true

  belongs_to :order
  belongs_to :selling_plan
end
