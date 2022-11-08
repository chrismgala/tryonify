class AddShopifyUpdatedToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :shopify_updated_at, :datetime
  end
end
