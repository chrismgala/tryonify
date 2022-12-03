# frozen_string_literal: true

desc "Update orders from Shopify to persist on local DB"
task update_orders: :environment do |_task, _args|
  puts "Updating orders..."

  shops = Shop.all

  shops.each do |shop|
    puts "Fetching orders for #{shop.shopify_domain}"
    Order.where(shop:).where(total_outstanding: nil).or(Order.where(shop:).where("total_outstanding > 0")).find_in_batches(batch_size: 20) do |orders|
      ids = orders.map { |x| "gid://shopify/Order/#{x.shopify_id}" }
      UpdateExistingOrdersJob.perform_later(shop.id, ids)
    end
  end

  puts "done."
end
