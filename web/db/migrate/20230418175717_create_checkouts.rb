# frozen_string_literal: true

class CreateCheckouts < ActiveRecord::Migration[7.0]
  def change
    create_table(:checkouts) do |t|
      t.string(:draft_order_id, null: false)
      t.string(:link)
      t.string(:name)
      t.references(:shop, null: false, foreign_key: true)

      t.timestamps
    end
  end
end
