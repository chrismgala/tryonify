# frozen_string_literal: true

class ChangePrepayToDecimal < ActiveRecord::Migration[7.0]
  def change
    change_column(:selling_plans, :prepay, :decimal, precision: 8, scale: 2)
  end
end
