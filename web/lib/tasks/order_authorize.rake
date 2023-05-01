# frozen_string_literal: true

desc "Authorize an order"
task :order_authorize, [:id] => :environment do |_task, args|
  puts "Authorizing order..."
  order = Order.find(args[:id])
  order.shop.with_shopify_session do
    OrderAuthorize.call(order)
  end
  puts "done."
end
