# frozen_string_literal: true

class Checkout < ApplicationRecord
  validates :draft_order_id, uniqueness: true, presence: true

  belongs_to :shop
end
