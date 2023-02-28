# frozen_string_literal: true

class CreateLineItem < ActiveRecord::Migration[7.0]
  def change
    create_table(:line_items) do |t|
      t.references(:order, on_delete: :cascade, foreign_key: true)
      t.references(:selling_plan)
      t.string(:shopify_id, index: { unique: true })
      t.string(:title, default: "", null: false)
      t.string(:variant_title, default: "", null: false)
      t.string(:image_url)
      t.integer(:quantity, default: 0, null: false)
      t.integer(:unfulfilled_quantity, default: 0, null: false)
      t.integer(:status, default: 0, null: false)
      t.boolean(:restockable, default: false)

      t.timestamps
    end
  end
end
