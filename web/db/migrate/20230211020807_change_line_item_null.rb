# frozen_string_literal: true

class ChangeLineItemNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null(:line_items, :variant_title, true)
  end
end
