# frozen_string_literal: true

desc "Authorize orders"
task authorize_orders: :environment do |_task, _args|
  puts "Authorizing orders..."

  order_ids = _args.extras

  if order_ids.empty?
    puts "No order IDs provided. Please provide comma-separated order IDs."
    puts "Usage: rake authorize_orders[1,2,3]"
    return
  end

  order_ids.each do |order_id|
    order_id = order_id.strip
    puts "Authorizing order #{order_id}..."

    begin
      order = Order.find(order_id)
      order.shop.with_shopify_session do
        OrderAuthorize.call(order)
      end
    rescue StandardError => e
      puts "Error authorizing order #{order_id}: #{e.message}"
    end
  end

  puts "done."
end
