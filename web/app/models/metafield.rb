# frozen_string_literal: true

class Metafield < ApplicationRecord
  validates :shopify_id, uniqueness: true

  belongs_to :shop
end
