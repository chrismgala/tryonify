class AddEmailToShop < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :email, :string
  end
end
