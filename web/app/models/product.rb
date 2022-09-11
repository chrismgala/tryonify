# frozen_string_literal: true

class Product < ApplicationRecord
  validates :shopify_id, presence: true
end