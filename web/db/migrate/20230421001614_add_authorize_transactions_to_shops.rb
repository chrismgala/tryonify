# frozen_string_literal: true

class AddAuthorizeTransactionsToShops < ActiveRecord::Migration[7.0]
  def change
    add_column(:shops, :authorize_transactions, :boolean, default: true)
  end
end
