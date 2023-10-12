class AddMaxDueDateToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :max_due_date, :datetime
  end
end
