class AddKlaviyoApiKeyToShop < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :klaviyo_public_key, :string
    add_column :shops, :klaviyo_private_key, :string
  end
end
