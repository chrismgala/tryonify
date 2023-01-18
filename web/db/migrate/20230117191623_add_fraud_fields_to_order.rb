# frozen_string_literal: true

class AddFraudFieldsToOrder < ActiveRecord::Migration[7.0]
  def change
    add_column(:orders, :ip_address, :string)
  end
end
