# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.references :shop, on_delete: :cascade
      t.string :shopify_id, index: { unique: true }
      t.datetime :due_date

      t.timestamps
    end
  end
end
