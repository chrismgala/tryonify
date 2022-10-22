desc 'Cancel store subscription'
task :cancel_subscription, %i[shop_domain id] => :environment do |_task, args|
  puts 'Cancel subscription...'

  shop = Shop.find_by!(shopify_domain: args[:shop_domain])

  return unless shop

  shop.with_shopify_session do
    service = CancelSubscription.new(args[:id])
    service.call
  end

  puts 'done.'
end
