class LineItemCascadeDeleteOnReturn < ActiveRecord::Migration[7.0]
  def up
    remove_foreign_key :returns, :line_items
    add_foreign_key :returns, :line_items, on_delete: :cascade
  end

  def down
    remove_foreign_key :returns, :line_items
    add_foreign_key :returns, :line_items
  end
end
