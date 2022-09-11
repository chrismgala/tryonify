class AddPlanToShop < ActiveRecord::Migration[7.0]
  def change
    add_reference :shops, :plan, index: true
  end
end
