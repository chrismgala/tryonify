# frozen_string_literal: true

desc "Void an authorization"
task :order_void_authorization, [:id] => :environment do |_task, args|
  puts "Voiding authorization..."
  order = Order.find(args[:id])
  order.shop.with_shopify_session do
    OrderVoidAuthorization.call(order)
  end
  puts "done."
end
