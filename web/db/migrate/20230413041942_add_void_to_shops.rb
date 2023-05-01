# frozen_string_literal: true

class AddVoidToShops < ActiveRecord::Migration[7.0]
  def change
    add_column(:shops, :void_authorizations, :boolean, default: false)
  end
end
