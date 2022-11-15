class AddMaxTrialItemsToShop < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :max_trial_items, :integer, default: 3
  end
end
