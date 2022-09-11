class CreateSellingPlanGroup < ActiveRecord::Migration[7.0]
  def change
    create_table :selling_plan_groups do |t|
      t.string :shopify_id, null: false, index: { unique: true }
      t.string :name, null: false, default: 'Free trial'
      t.text :description, default: 'Your free trial program'

      t.references :shop, null: false, on_delete: :cascade

      t.timestamps
    end
  end
end
