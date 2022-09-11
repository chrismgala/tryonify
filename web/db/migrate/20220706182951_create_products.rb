class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :shopify_id, null: false, index: { unique: true }
      t.references :shop, on_delete: :cascade

      t.timestamps
    end
  end
end
