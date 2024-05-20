desc 'List webhooks'
task list_webhooks: :environment do |_task, _args|
  puts 'Listing webhooks...'

  shops = Shop.all

  shops.each do |shop|
    shop.with_shopify_session do
      puts "Shop: #{shop.shopify_domain}"
      webhooks = ShopifyAPI::Webhook.all
      puts webhooks.inspect
    end
  end

  puts 'done.'
end
