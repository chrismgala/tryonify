desc 'Update webhooks'
task update_webhooks: :environment do |_task, _args|
  puts 'Updating webhooks...'

  shops = Shop.all

  shops.each do |shop|
    return unless ShopifyApp.configuration.has_webhooks?

    ShopifyAPI::Auth::Session.temp(shop: shop.shopify_domain, access_token: shop.shopify_token) do |session|
      ShopifyApp::WebhooksManager.add_registrations
      result = ShopifyAPI::Webhooks::Registry.register_all(session:)
      puts result.inspect
    end
  end

  puts 'done.'
end
