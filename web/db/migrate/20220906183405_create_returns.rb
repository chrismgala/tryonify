class CreateReturns < ActiveRecord::Migration[7.0]
  def change
    create_table :returns do |t|
      t.references :shop, on_delete: :cascade
      t.references :order, on_delete: :cascade
      t.string :shopify_id, index: { unique: true }
      t.string :title
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
