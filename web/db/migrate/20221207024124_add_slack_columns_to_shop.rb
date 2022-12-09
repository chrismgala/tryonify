# frozen_string_literal: true

class AddSlackColumnsToShop < ActiveRecord::Migration[7.0]
  def change
    add_column(:shops, :slack_token, :string)
  end
end
