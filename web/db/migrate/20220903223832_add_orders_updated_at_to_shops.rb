class AddOrdersUpdatedAtToShops < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :orders_updated_at, :datetime
  end
end
