# frozen_string_literal: true

class AddKindToPayments < ActiveRecord::Migration[7.0]
  def change
    add_column(:payments, :kind, :integer)
  end
end
