# frozen_string_literal: true

class Return < ApplicationRecord
  validates :shopify_id, presence: true, uniqueness: true

  belongs_to :shop
  belongs_to :order, dependent: :destroy, counter_cache: true
  has_many :return_line_items, dependent: :destroy

  enum :status, [:canceled, :closed, :declined, :open, :requested]

  accepts_nested_attributes_for :return_line_items
end