# frozen_string_literal: true

class AddOrderFields < ActiveRecord::Migration[7.0]
  def change
    add_column(:orders, :fully_paid, :boolean, default: false)
    add_column(:orders, :total_outstanding, :decimal)
  end
end
