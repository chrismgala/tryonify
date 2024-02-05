class CreateValidations < ActiveRecord::Migration[7.0]
  def change
    create_table :validations do |t|
      t.string :shopify_id, null: false, index: { unique: true }
      t.boolean :enabled, default: false
      t.references :shop, on_delete: :cascade

      t.timestamps
    end
  end
end
