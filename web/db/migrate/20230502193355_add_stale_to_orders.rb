# frozen_string_literal: true

class AddStaleToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column(:orders, :stale, :boolean, default: false)
  end
end
