# frozen_string_literal: true

class AddCanceledAtToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column(:orders, :cancelled_at, :datetime)
  end
end
