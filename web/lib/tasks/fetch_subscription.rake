# frozen_string_literal: true

desc "Fetch app subscription details"
task :extend_trial, [:shop_domain] => :environment do |_task, args|
  puts "Fetching subscription details..."

  shop = Shop.find_by!(shopify_domain: args[:shop_domain])

  return unless shop

  shop.with_shopify_session do
    service = FetchAppSubscription.new
    service.call

    return unless service.app

    puts service.app.inspect
  end

  puts "done."
end
