class ResetOrdersCacheCounters < ActiveRecord::Migration[7.0]
  def up
    Order.all.each do |order|
      Order.reset_counters(order.id, :returns)
    end
  end

  def down; end
end
