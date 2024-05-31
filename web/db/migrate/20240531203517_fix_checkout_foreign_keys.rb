class FixCheckoutForeignKeys < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :checkouts, :shops
    add_foreign_key :checkouts, :shops, on_delete: :cascade
  end
end
