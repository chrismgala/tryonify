class AddGatewaySettings < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :reauthorize_paypal, :boolean, default: true
    add_column :shops, :reauthorize_shopify_payments, :boolean, default: true
  end
end
