# frozen_string_literal: true

desc "Update webhooks"
task update_webhooks: :environment do |_task, _args|
  puts "Updating webhooks..."

  shops = Shop.all

  shops.each do |shop|
    shop.with_shopify_session do
      session = ShopifyAPI::Context.active_session
      ShopifyApp::WebhooksManager.recreate_webhooks!(session: session)
      ShopifyApp::WebhooksManager.queue(session.shop, session.access_token)
    rescue => err
      puts err.inspect
    end
  end

  puts "done."
end
