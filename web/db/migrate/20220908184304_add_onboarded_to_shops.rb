class AddOnboardedToShops < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :onboarded, :boolean, default: false
  end
end
