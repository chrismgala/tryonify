# frozen_string_literal: true

class CreateSellingPlanGroup
  class InvalidRequest < StandardError; end

  attr_accessor :selling_plan_group, :error

  def initialize(selling_plan_group)
    @selling_plan_group = selling_plan_group
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = <<~QUERY
      mutation sellingPlanGroupCreate($name: String!, $description: String!, $plan: [SellingPlanInput!]) {
        sellingPlanGroupCreate(
          input: {
            appId: "tryonify",
            name: $name,
            description: $description,
            merchantCode: $name,
            options: ["default"],
            sellingPlansToCreate: $plan
          }
        ) {
          sellingPlanGroup {
            id
            sellingPlans(first: 10) {
              edges {
                node {
                  id
                  name
                  description
                  billingPolicy {
                    ... on SellingPlanFixedBillingPolicy {
                      remainingBalanceChargeTimeAfterCheckout
                      checkoutCharge {
                        value {
                          ... on MoneyV2 {
                            amount
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          userErrors {
            field
            message
          }
        }
      }
    QUERY

    variables = {
      name: @selling_plan_group.name,
      description: @selling_plan_group.description,
      plan: create_plan(@selling_plan_group.selling_plan)
    }

    response = @client.query(query:, variables:)

    # Raise an error if the query is unsuccessful
    unless response.body['errors'].nil?
      raise CreateSellingPlanGroup::InvalidRequest,
            response.body.dig('errors', 0, 'message') and return
    end

    @selling_plan_group = response.body.dig('data', 'sellingPlanGroupCreate', 'sellingPlanGroup')
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[CreateSellingPlanGroup Failed]: #{e.message}")
    @error = e
    raise e
  end

  def create_plan(plan)
    trial_days_integer = plan.trial_days.to_i
    trial_days_iso = trial_days_integer.days.iso8601

    [{
      name: plan.name,
      description: plan.description,
      options: ['default'],
      billingPolicy: {
        fixed: {
          checkoutCharge: {
            type: 'PRICE',
            value: {
              fixedValue: plan.prepay
            }
          },
          remainingBalanceChargeTimeAfterCheckout: trial_days_iso,
          remainingBalanceChargeTrigger: 'TIME_AFTER_CHECKOUT'
        }
      },
      category: 'TRY_BEFORE_YOU_BUY',
      inventoryPolicy: {
        reserve: 'ON_SALE'
      },
      deliveryPolicy: {
        fixed: {
          fulfillmentTrigger: 'ASAP'
        }
      },
      pricingPolicies: {
        fixed: {
          adjustmentType: 'FIXED_AMOUNT',
          adjustmentValue: {
            fixedValue: 0
          }
        }
      }
    }]
  end
end
