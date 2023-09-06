class AddCancelPrepaidToShops < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :cancel_prepaid_cards, :boolean, default: true
  end
end
