# frozen_string_literal: true

class CreateMetafields < ActiveRecord::Migration[7.0]
  def change
    create_table(:metafields) do |t|
      t.references(:shop, on_delete: :cascade)
      t.string(:shopify_id, index: { unique: true })
      t.string(:namespace, null: false)
      t.string(:key, null: false)
      t.string(:value)

      t.timestamps
    end
  end
end
