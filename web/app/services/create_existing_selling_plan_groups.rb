class CreateExistingSellingPlanGroups
  def initialize(shop, cursor = nil)
    @shop = shop
    @cursor = cursor
  end

  def call
    fetch_plans
  rescue StandardError => e
    Rails.logger.error(e)
    raise e
  end

  def fetch_plans(pagination = {})
    service = FetchSellingPlanGroups.new(pagination)
    service.call

    service.selling_plan_groups['edges'].each do |selling_plan_group|
      new_selling_plan_group = SellingPlanGroup.new(
        shopify_id: selling_plan_group['node']['id'],
        name: selling_plan_group['node']['name'],
        description: selling_plan_group['node']['description'],
        shop: @shop
      )

      selling_plan = selling_plan_group.dig('node', 'sellingPlans', 'edges').first
      new_selling_plan = SellingPlan.new(
        shopify_id: selling_plan.dig('node', 'id'),
        name: selling_plan.dig('node', 'name'),
        description: selling_plan.dig('node', 'description'),
        prepay: selling_plan.dig('node', 'billingPolicy', 'checkoutCharge', 'value', 'amount'),
        trial_days: ActiveSupport::Duration.parse(selling_plan.dig('node', 'billingPolicy',
                                                                   'remainingBalanceChargeTimeAfterCheckout')).in_days.to_i
      )

      new_selling_plan_group.selling_plan = new_selling_plan

      new_selling_plan_group.save! unless SellingPlanGroup.exists?(shopify_id: new_selling_plan_group.shopify_id)
    end

    if service.selling_plan_groups.dig('pageInfo', 'hasNextPage')
      pagination = {
        next: 'true',
        cursor: service.selling_plan_groups.dig('pageInfo', 'endCursor')
      }

      fetch_plans(pagination)
    end
  end
end
