# frozen_string_literal: true

class ReferenceTransactionsOnPayments < ActiveRecord::Migration[7.0]
  def change
    add_reference(:payments, :parent_transaction, foreign_key: { to_table: :transactions })
  end
end
