# frozen_string_literal: true

desc "Delete webhooks"
task delete_webhooks: :environment do |_task, _args|
  puts "Deleting webhooks..."

  shops = Shop.all

  shops.each do |shop|
    shop.with_shopify_session do
      session = ShopifyAPI::Context.active_session
      ShopifyApp::WebhooksManager.destroy_webhooks(session: session)
    rescue => err
      puts err.inspect
    end
  end

  puts "done."
end
