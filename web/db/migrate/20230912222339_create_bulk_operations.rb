class CreateBulkOperations < ActiveRecord::Migration[7.0]
  def change
    create_table :bulk_operations do |t|
      t.string :shopify_id, index: { unique: true }
      t.datetime :completed_at
      t.string :error_code
      t.string :url
      t.string :status
      t.text :query
      t.references :shop, null: false, foreign_key: true

      t.timestamps
    end
  end
end
