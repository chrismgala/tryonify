desc 'Bulk update orders from Shopify'
task bulk_order_update: :environment do |_task, _args|
  puts 'Creating bulk operations...'

  shops = Shop.all

  shops.each do |shop|
    puts "Bulk order operation for #{shop.shopify_domain}"
    BulkOperationsRunJob.perform_later(shop)
  end

  puts 'done.'
end
