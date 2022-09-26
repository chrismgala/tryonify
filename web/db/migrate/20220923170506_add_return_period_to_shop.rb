class AddReturnPeriodToShop < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :return_period, :integer, default: 14
  end
end
