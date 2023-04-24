# frozen_string_literal: true

class CreateTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table(:transactions) do |t|
      t.string(:shopify_id, null: false)
      t.references(:order, null: false, foreign_key: true)
      t.references(:parent_transaction, foreign_key: { to_table: :transactions })
      t.integer(:kind, null: false)
      t.decimal(:amount, null: false)
      t.string(:error)
      t.json(:receipt)

      t.timestamps
    end
  end
end
