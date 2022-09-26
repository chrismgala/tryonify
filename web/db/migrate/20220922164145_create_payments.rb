class CreatePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :payments do |t|
      t.string :idempotency_key, null: false, index: { unique: true }
      t.string :payment_reference_id
      t.string :error
      t.string :status, default: 'PENDING'

      t.references :order, on_delete: :cascade, foreign_key: true

      t.timestamps
    end
  end
end
