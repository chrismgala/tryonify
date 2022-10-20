desc 'Update webhooks'
task update_webhooks: :environment do |_task, _args|
  puts 'Updating webhooks...'

  shops = Shop.all

  shops.each do |shop|
    shop.with_shopify_session do
      webhook = ShopifyAPI::Webhook.new
      webhook.topic = 'orders/create'
      webhook.address = 'https://tryonify.ngrok.io/api/webhooks/orders_create'
      webhook.format = 'json'

      webhook.save!
    end
  end

  puts 'done.'
end
