# frozen_string_literal: true

class Validation < ApplicationRecord
  validates :shopify_id, presence: true, uniqueness: true

  belongs_to :shop
end
