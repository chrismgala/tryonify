class AddMantleApiTokenToShops < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :mantle_api_token, :string
  end
end
