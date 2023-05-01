# frozen_string_literal: true

class AddColumnVoidedToTransactions < ActiveRecord::Migration[7.0]
  def change
    add_column(:transactions, :voided, :boolean, default: false)
  end
end
