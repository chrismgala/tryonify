class AddFulfillmentStatusToOrder < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :fulfillment_status, :string, default: 'UNFULFILLED'
    rename_column :orders, :status, :financial_status
  end
end
