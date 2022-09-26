class AddMandateIdToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :mandate_id, :string
  end
end
