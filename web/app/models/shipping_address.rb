# frozen_string_literal: true

class ShippingAddress < ApplicationRecord
  include PgSearch::Model

  belongs_to :order
end
