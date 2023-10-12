class AddLineItemToReturns < ActiveRecord::Migration[7.0]
  def change
    add_reference :returns, :line_item, foreign_key: true
  end
end
