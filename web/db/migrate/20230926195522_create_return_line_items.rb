class CreateReturnLineItems < ActiveRecord::Migration[7.0]
  def change
    create_table :return_line_items do |t|
      t.string :shopify_id, null: false, index: { unique: true }
      t.references :return, null: false, foreign_key: { on_delete: :cascade }
      t.references :line_item, null: false, foreign_key: { on_delete: :cascade }
      t.integer :quantity, null: false

      t.timestamps
    end
  end
end
