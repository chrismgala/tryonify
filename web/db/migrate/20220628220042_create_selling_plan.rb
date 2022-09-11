class CreateSellingPlan < ActiveRecord::Migration[7.0]
  def change
    create_table :selling_plans do |t|
      t.string :shopify_id, index: { unique: true }
      t.string :name, null: false, default: 'Free trial'
      t.text :description, default: 'Try this product free for 14 days'
      t.integer :prepay, default: 0
      t.integer :trial_days, default: 14

      t.references :selling_plan_group, on_delete: :cascade

      t.timestamps
    end
  end
end
