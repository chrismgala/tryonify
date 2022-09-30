class AddNotNullToShopsReturnPeriod < ActiveRecord::Migration[7.0]
  def change
    change_column_null :shops, :return_period, false
  end
end
