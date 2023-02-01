# frozen_string_literal: true

class ChangePrepayToDecimal < ActiveRecord::Migration[7.0]
  def change
    change_column(:selling_plans, :prepay, :decimal, precision: 5, scale: 3)
  end
end
