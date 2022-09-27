class AddSettingsToShops < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :return_explainer, :text
    add_column :shops, :allow_automatic_payments, :boolean, default: true
  end
end
