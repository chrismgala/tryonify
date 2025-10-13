# frozen_string_literal: true

desc "Update orders by ids"
task :update_orders, [:ids] => :environment do |_task, args|
  puts "Updating orders..."

  order_ids = args[:ids]&.split(',') || []

  if order_ids.empty?
    puts "No order IDs provided. Please provide comma-separated order IDs."
    puts "Usage: rake update_orders['1,2,3']"
    return
  end

  order_ids.each do |order_id|
    order_id = order_id.strip
    puts "Updating order #{order_id}..."

    begin
      order = Order.find(order_id)
      order.shop.with_shopify_session do
        graphql_order = FetchOrder.call(id: order.shopify_id)

        puts "GraphQL order: #{graphql_order.inspect}"

        built_order = OrderBuild.call(shop_id: order.shop_id, data: graphql_order.body.dig("data", "order"))
        OrderUpdate.call(order_attributes: built_order, order: order)
        
        puts "Successfully updated order #{order_id}"
      end
    rescue StandardError => e
      puts "Error updating order #{order_id}: #{e.message}"
    end
  end

  puts "done."
end
