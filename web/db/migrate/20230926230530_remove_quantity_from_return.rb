class RemoveQuantityFromReturn < ActiveRecord::Migration[7.0]
  def change
    remove_column :returns, :quantity, :integer
    remove_column :returns, :line_item_id, :integer
  end
end
