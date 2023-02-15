# frozen_string_literal: true

class RemoveShippingAddressColumns < ActiveRecord::Migration[7.0]
  def change
    remove_column(:shipping_addresses, :first_name)
    remove_column(:shipping_addresses, :last_name)
  end
end
