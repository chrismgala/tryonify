class AddEnqueuedAtToPayments < ActiveRecord::Migration[7.0]
  def change
    add_column :payments, :enqueued_at, :datetime
  end
end
