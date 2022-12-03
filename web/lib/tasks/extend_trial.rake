# frozen_string_literal: true

desc "Extend trial by 60 days"
task :extend_trial, [:shop_domain] => :environment do |_task, args|
  puts "Extending trial..."

  shop = Shop.find_by!(shopify_domain: args[:shop_domain])

  return unless shop

  shop.with_shopify_session do
    service = ExtendTrial.new
    service.call
  end

  puts "done."
end
