class AddReturnsCounterToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :returns_count, :integer
  end
end
