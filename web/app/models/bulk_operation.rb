# frozen_string_literal: true

class BulkOperation < ApplicationRecord
  validates :shopify_id, presence: true, uniqueness: true
  
  has_one :shop
end