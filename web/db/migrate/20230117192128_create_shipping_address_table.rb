# frozen_string_literal: true

class CreateShippingAddressTable < ActiveRecord::Migration[7.0]
  def change
    create_table(:shipping_address_tables) do |t|
      t.references(:order, on_delete: :cascade)
      t.string(:first_name)
      t.string(:last_name)
      t.string(:address1)
      t.string(:address2)
      t.string(:city)
      t.string(:zip)
      t.string(:province)
      t.string(:country)
      t.string(:country_code)
      t.string(:province_code)
      t.timestamps
    end
  end
end
