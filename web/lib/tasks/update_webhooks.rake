desc "Update webhooks"
task :update_webhooks => :environment do |task, args|
  puts "Updating webhooks..."

  shops = Shop.all

  shops.each do |shop|
    shop.with_shopify_session do
      session = ShopifyAPI::Context.active_session
      return unless ShopifyApp.configuration.has_webhooks?

      ShopifyApp.configuration.webhooks.each do |attributes|
        ShopifyAPI::Webhooks::Registry.unregister(topic: attributes[:topic], session: session)
      end

      ShopifyApp::WebhooksManager.add_registrations

      resp = ShopifyAPI::Webhooks::Registry.register_all(session: session)
      puts resp.inspect
    end
  end

  puts "done."
end