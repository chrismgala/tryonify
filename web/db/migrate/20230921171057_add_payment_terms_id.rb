class AddPaymentTermsId < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :payment_terms_id, :string
  end
end
