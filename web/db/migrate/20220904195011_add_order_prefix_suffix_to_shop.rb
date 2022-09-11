class AddOrderPrefixSuffixToShop < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :order_number_format_prefix, :string, default: "#"
    add_column :shops, :order_number_format_suffix, :string
  end
end
