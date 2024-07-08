class CreateJobs < ActiveRecord::Migration[7.0]
  def change
    create_table :jobs do |t|
      t.string :shopify_id, null: false, index: { unique: true }
      t.string :type
      t.boolean :done, default: false
      t.references :jobable, polymorphic: true, index: true
      t.references :shop, foreign_key: true

      t.timestamps
    end
  end
end
