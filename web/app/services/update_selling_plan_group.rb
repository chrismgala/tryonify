# frozen_string_literal: true

class UpdateSellingPlanGroup
  class InvalidRequest < StandardError; end

  attr_accessor :selling_plan_group, :error

  def initialize(selling_plan_group)
    @selling_plan_group = selling_plan_group
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
    puts @selling_plan_group.inspect
  end

  def call
    query = <<~QUERY
      mutation sellingPlanGroupUpdate($id: ID!, $name: String!, $description: String!, $updatePlans: [SellingPlanInput!]) {
        sellingPlanGroupUpdate(
          id: $id,
          input: {
            appId: "tryonify",
            name: $name,
            description: $description,
            merchantCode: $name,
            options: ["default"],
            sellingPlansToUpdate: $updatePlans,
          }
        ) {
          sellingPlanGroup {
            id
            name
            description
            merchantCode
            sellingPlans(first: 10) {
              edges {
                node {
                  id
                  name
                  description
                  options
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
            products(first: 250) {
              edges {
                node {
                  id
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

    plan = create_plan(@selling_plan_group.selling_plan)

    variables = {
      id: @selling_plan_group.shopify_id,
      name: @selling_plan_group.name,
      description: @selling_plan_group.description || "",
      updatePlans: [plan],
    }

    response = @client.query(query:, variables:)

    # Raise an error if the query is unsuccessful
    unless response.body["errors"].nil?
      raise UpdateSellingPlanGroup::InvalidRequest,
        response.body.dig("errors", 0, "message") and return
    end

    @selling_plan_group = response.body.dig("data", "sellingPlanGroupUpdate", "sellingPlanGroup")
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[UpdateSellingPlanGroup Failed]: #{e.message}")
    @error = e
    raise e
  end

  def create_plan(plan)
    trial_days_integer = plan.trial_days.to_i

    raise "Trial days requires an integer" unless trial_days_integer.is_a?(Integer)

    trial_days_iso = trial_days_integer.days.iso8601

    {
      id: plan.shopify_id,
      name: plan.name,
      description: plan.description || "",
      options: ["default"],
      billingPolicy: {
        fixed: {
          checkoutCharge: {
            type: "PRICE",
            value: {
              fixedValue: plan.prepay,
            },
          },
          remainingBalanceChargeTimeAfterCheckout: trial_days_iso,
          remainingBalanceChargeTrigger: "TIME_AFTER_CHECKOUT",
        },
      },
      category: "TRY_BEFORE_YOU_BUY",
      inventoryPolicy: {
        reserve: "ON_SALE",
      },
      deliveryPolicy: {
        fixed: {
          fulfillmentTrigger: "ASAP",
        },
      },
      pricingPolicies: {
        fixed: {
          adjustmentType: "FIXED_AMOUNT",
          adjustmentValue: {
            fixedValue: 0,
          },
        },
      },
    }
  end
end
