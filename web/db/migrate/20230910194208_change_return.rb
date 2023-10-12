class ChangeReturn < ActiveRecord::Migration[7.0]
  def change
    add_column :returns, :status, :integer
    add_column :returns, :quantity, :integer
    remove_column :returns, :title, :string
    remove_column :returns, :active, :boolean
  end
end
