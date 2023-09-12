# frozen_string_literal: true

class Return < ApplicationRecord
  validates :shopify_id, presence: true, uniqueness: true

  belongs_to :shop
  belongs_to :order, counter_cache: true
  belongs_to :line_item

  enum :status, [:canceled, :closed, :declined, :open, :requested]
end