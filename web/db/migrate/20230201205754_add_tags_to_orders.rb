# frozen_string_literal: true

class AddTagsToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column(:orders, :tags, :string, array: true)
  end
end
