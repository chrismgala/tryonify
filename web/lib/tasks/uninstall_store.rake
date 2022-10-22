require 'rest-client'
require 'json'

desc 'Uninstall store'
task :uninstall_store, [:shop_domain] => :environment do |_task, args|
  puts 'Uninstall store...'

  shop = Shop.find_by!(shopify_domain: args[:shop_domain])

  return unless shop

  revoke_url = "https://#{shop.shopify_domain}/admin/api_permissions/current.json"

  headers = {
    'X-Shopify-Access-Token' => shop.shopify_token,
    content_type: 'application/json',
    accept: 'application/json'
  }

  RestClient.delete(revoke_url, headers)

  puts 'done.'
end
