class AddFulfillmentLineItemIdToReturnLineItems < ActiveRecord::Migration[7.0]
  def change
    add_column :return_line_items, :fulfillment_line_item_id, :string, null: false
  end
end
