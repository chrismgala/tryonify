# frozen_string_literal: true

desc "Updating order"
task :update_order, [:id] => :environment do |_task, args|
  puts "Updating order..."

  order_id = args[:id]

  puts "Updating order #{order_id}..."

  order = Order.find(order_id)
  order.shop.with_shopify_session do
    graphql_order = FetchOrder.call(id: order.shopify_id)

    puts "GraphQL order: #{graphql_order.inspect}"

    built_order = OrderBuild.call(shop_id: order.shop_id, data: graphql_order.body.dig("data", "order"))
    OrderUpdate.call(order_attributes: built_order, order: order)
  rescue StandardError => e
    puts "Error updating order #{order_id}: #{e.message}"
  end

  puts "done."
end
