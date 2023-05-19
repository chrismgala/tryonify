# frozen_string_literal: true

class AddIgnoreToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column(:orders, :ignored_at, :datetime, index: true)
  end
end
