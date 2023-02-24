# frozen_string_literal: true

desc "Convert order ID to gid"
task convert_order_id: :environment do |_task, _args|
  puts "Converting order IDs..."

  Order.find_each do |order|
    unless order.shopify_id.start_with?("gid")
      order.shopify_id = "gid://shopify/Order/#{order.shopify_id}"
      order.save!
    end
  end

  puts "done."
end
