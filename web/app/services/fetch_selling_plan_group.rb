# frozen_string_literal: true

class FetchSellingPlanGroup
  class InvalidRequest < StandardError; end

  attr_accessor :selling_plan_group, :error

  def initialize(id, pagination = { first: 20, after: nil })
    @id = id
    @pagination = pagination
    @selling_plan_group = nil
    @error = nil
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = @pagination[:first] ? nextPage : previousPage

    variables = {
      id: @id,
      first: @pagination[:first].to_i,
      last: @pagination[:last].to_i,
      before: @pagination[:before],
      after: @pagination[:after],
    }

    response = @client.query(query:, variables:)

    unless response.body["errors"].nil?
      raise FetchSellingPlanGroup::InvalidRequest,
        response.body.dig("errors", 0, "message") and return
    end

    @selling_plan_group = response.body.dig("data", "sellingPlanGroup")
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[FetchSellingPlanGroup Failed]: #{e}")
    @error = e.message
  end

  def nextPage
    <<~QUERY
      query sellingPlanGroup($id: ID!, $first: Int!, $after: String) {
        sellingPlanGroup(id: $id) {
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
          products(first: $first, after: $after) {
            edges {
              node {
                id
                title
                images(first: 1) {
                  edges {
                    node {
                      altText
                      url
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
      }
    QUERY
  end

  def previousPage
    <<~QUERY
      query sellingPlanGroup($id: ID!, $last: Int!, $before: String!) {
        sellingPlanGroup(id: $id) {
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
          products(last: $last, before: $before) {
            edges {
              node {
                id
                title
                images(first: 1) {
                  edges {
                    node {
                      altText
                      url
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
      }
    QUERY
  end
end
