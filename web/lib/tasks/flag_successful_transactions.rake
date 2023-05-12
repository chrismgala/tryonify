# frozen_string_literal: true

desc "Flag successful transactions"
task :flag_successful_transactions, [:shop_domain] => :environment do |_task, args|
  puts "Flagging successful transactions..."

  shop = Shop.find_by!(shopify_domain: args[:shop_domain])

  if shop.nil?
    puts "Shop #{args[:shop_domain]} not found."
    return
  end

  shop.with_shopify_session do
    shop.orders.pending.each do |order|
      OrderTransactionFetch.call(order)
      sleep 1
    end
  end

  puts "done."
end
