desc 'Update webhooks'
task update_webhooks: :environment do |_task, _args|
  puts 'Updating webhooks...'

  shops = Shop.all

  shops.each do |shop|
    shop.with_shopify_session do
      webhook = ShopifyAPI::Webhook.new
      webhook.topic = 'orders/updated'
      webhook.address = 'https://tryonify.ngrok.io/api/webhooks/orders_updated'
      webhook.format = 'json'

      webhook.save!
    end
  end

  puts 'done.'
end
