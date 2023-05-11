# frozen_string_literal: true

class AddStatusToTransactions < ActiveRecord::Migration[7.0]
  def change
    add_column(:transactions, :status, :integer, default: 0)
    add_column(:transactions, :gateway, :string)
  end
end
