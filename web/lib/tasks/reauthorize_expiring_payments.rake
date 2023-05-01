# frozen_string_literal: true

desc "Reauthorize expiring payments"
task reauthorize_expiring_payments: :environment do |_task, _args|
  puts "Reauthorize expiring payments..."

  Shop.find_each do |shop|
    ReauthorizeOrders.call(shop)
  end

  puts "done."
end
