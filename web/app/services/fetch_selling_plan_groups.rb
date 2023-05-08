# frozen_string_literal: true

class FetchSellingPlanGroups
  class InvalidRequest < StandardError; end

  attr_accessor :selling_plan_groups, :error

  NEXT_SELLING_PLAN_GROUPS_QUERY = <<~QUERY
    query sellingPlanGroups($first: Int, $after: String) {
      sellingPlanGroups(first: $first, after: $after) {
        edges {
          node {
            id
            name
            description
            options
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
          }
        }
        pageInfo {
          hasPreviousPage
          hasNextPage
          startCursor
          endCursor
        }
      }
    }
  QUERY

  PREVIOUS_SELLING_PLAN_GROUPS_QUERY = <<~QUERY
    query sellingPlanGroups($last: Int, $before: String) {
      sellingPlanGroups(last: $last, before: $before) {
        edges {
          node {
            id
            name
            description
            options
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
          }
        }
        pageInfo {
          hasPreviousPage
          hasNextPage
          startCursor
          endCursor
        }
      }
    }
  QUERY

  def initialize(pagination = {})
    @selling_plan_groups = nil
    @pagination = pagination
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = @pagination[:last] ? PREVIOUS_SELLING_PLAN_GROUPS_QUERY : NEXT_SELLING_PLAN_GROUPS_QUERY

    variables = {
      first: @pagination[:first] ? @pagination[:first].to_i : 20,
      last: @pagination[:last].to_i,
      before: @pagination[:before],
      after: @pagination[:after],
    }

    response = @client.query(query:, variables:)

    unless response.body["errors"].nil?
      raise FetchSellingPlanGroups::InvalidRequest,
        response.body.dig("errors", 0, "message") and return
    end

    @selling_plan_groups = response.body["data"]["sellingPlanGroups"]
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[FetchSellingPlanGroups Failed]: #{e.message}")
    @error = e.message
    raise e
  end
end
