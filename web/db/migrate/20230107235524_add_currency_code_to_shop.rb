# frozen_string_literal: true

class AddCurrencyCodeToShop < ActiveRecord::Migration[7.0]
  def change
    add_column(:shops, :currency_code, :string, null: false, default: "USD")
  end
end
