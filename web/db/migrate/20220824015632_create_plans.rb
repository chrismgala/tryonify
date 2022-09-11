class CreatePlans < ActiveRecord::Migration[7.0]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.integer :trial_days, default: 0
      t.decimal :price, precision: 8, scale: 2, null: false
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
