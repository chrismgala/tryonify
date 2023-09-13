desc 'Fetch orders from Shopify to persist on local DB'
task bulk_order_update: :environment do |_task, _args|
  puts 'Fetching orders...'

  shops = Shop.all

  shops.each do |shop|
    puts "Fetching orders for #{shop.shopify_domain}"
    FetchExistingOrdersJob.perform_later(shop.id, nil)
  end

  puts 'done.'
end
