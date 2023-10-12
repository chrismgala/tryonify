class FixForeignKeys < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :returns, :orders
    add_foreign_key :returns, :orders, on_delete: :cascade

    remove_foreign_key :line_items, :orders
    add_foreign_key :line_items, :orders, on_delete: :cascade

    remove_foreign_key :return_line_items, :returns
    add_foreign_key :return_line_items, :returns, on_delete: :cascade

    remove_foreign_key :return_line_items, :line_items
    add_foreign_key :return_line_items, :line_items, on_delete: :cascade

    remove_foreign_key :transactions, :orders
    add_foreign_key :transactions, :orders, on_delete: :cascade
  end
end
