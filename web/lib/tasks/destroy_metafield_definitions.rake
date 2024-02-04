# frozen_string_literal: true

desc "Destroy metafield definitions"
task :destroy_metafield_definitions, [:shop_domain] => :environment do |_task, args|
  puts "Destroying metafield definitions..."

  shop = Shop.find_by!(shopify_domain: args[:shop_domain])

  return unless shop

  shop.with_shopify_session do
    response = Shopify::MetafieldDefinitions::Fetch.call(namespace: "$app:settings", owner_type: "SHOP")
    response.body.dig("data", "metafieldDefinitions", "edges")&.each do |edge|
      Shopify::MetafieldDefinitions::Destroy.call(id: edge.dig("node", "id"), delete_all: true)
    end
  end

  puts "done."
end
