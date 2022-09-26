class AddClosedAtToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :closed_at, :datetime
  end
end
