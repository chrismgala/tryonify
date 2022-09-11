class AddNameToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :name, :string, null: false
    add_column :orders, :status, :string, null: false
  end
end
