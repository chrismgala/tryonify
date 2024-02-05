# frozen_string_literal: true

desc "Delete validation"
task :delete_validation, [:shop_domain] => :environment do |_task, args|
  puts "Deleting validation..."

  shop = Shop.find_by!(shopify_domain: args[:shop_domain])

  return unless shop

  shop.with_shopify_session do
    return unless shop.validation.present?

    response = Shopify::Validations::Delete.call(id: shop.validation.shopify_id)
    puts response.inspect
  end

  puts "done."
end
