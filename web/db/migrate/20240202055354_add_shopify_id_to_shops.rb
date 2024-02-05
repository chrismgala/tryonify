class AddShopifyIdToShops < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :shopify_id, :string
  end
end
