# frozen_string_literal: true

desc "Reauthorize expiring payments"
task reauthorize_expiring_payments: :environment do |_task, _args|
  puts "Reauthorize expiring payments..."

  Shop.find_each do |shop|
    shop.with_shopify_session do
      shop.orders.pending.find_each do |order|
        if order.should_reauthorize?
          OrderAuthorizeJob.perform_later(order.id)
        end
      end
    end
  end

  puts "done."
end
