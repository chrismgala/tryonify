desc "Fetch orders from Shopify to persist on local DB"
task :fetch_orders => :environment do |task, args|
  puts "Fetching orders..."

  shops = Shop.all

  shops.each do |shop|
    puts "Fetching orders for #{shop.shopify_domain}"
    FetchExistingOrdersJob.perform_later(shop.id, nil)
  end

  puts "done."
end