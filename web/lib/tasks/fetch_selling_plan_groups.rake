desc 'Fetch selling plan groups'
task fetch_selling_plan_groups: :environment do |_task, _args|
  puts 'Fetching selling plan groups...'

  shops = Shop.all

  shops.each do |shop|
    CreateExistingSellingPlanGroupsJob.perform_later(shop.id) if check_billing(shop)
  end

  puts 'done.'
end

EXCLUDED_FROM_BILLING = ['tryonify-dev.myshopify.com', 'paskho.myshopify.com'].freeze

def check_billing(shop)
  return true if EXCLUDED_FROM_BILLING.include? shop.shopify_domain

  shop.with_shopify_session do
    service = FetchAppSubscription.new
    subscriptions = service.call

    # Redirect to billing if no active subscription
    false unless subscriptions.length > 0
  end
end
