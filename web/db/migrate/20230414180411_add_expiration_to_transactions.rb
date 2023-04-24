# frozen_string_literal: true

class AddExpirationToTransactions < ActiveRecord::Migration[7.0]
  def change
    add_column(:transactions, :authorization_expires_at, :datetime)
    add_column(:transactions, :payment_id, :string)
  end
end
