class AddForeignKeys < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :orders, :shops, on_delete: :cascade
    add_foreign_key :selling_plan_groups, :shops, on_delete: :cascade
    add_foreign_key :selling_plans, :selling_plan_groups, on_delete: :cascade
    add_foreign_key :products, :shops, on_delete: :cascade
    add_foreign_key :returns, :orders, on_delete: :cascade
  end
end
