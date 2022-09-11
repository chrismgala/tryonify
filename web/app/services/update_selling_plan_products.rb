# frozen_string_literal: true

class UpdateSellingPlanProducts
  class InvalidRequest < StandardError; end

  attr_accessor :error

  def initialize(shopify_id, product_ids)
    @id = shopify_id
    @product_ids = product_ids
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = <<~QUERY
      mutation sellingPlanGroupAddProducts($id: ID!, $productIds: [ID!]!) {
        sellingPlanGroupAddProducts(id: $id, productIds: $productIds) {
          sellingPlanGroup {
            id
            name
            sellingPlans(first: 1) {
              edges {
                node {
                  id
                  name
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
            products(first: 20) {
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

    variables = {
      id: @id,
      productIds: @product_ids
    }

    response = @client.query(query: query, variables: variables)

    raise UpdateSellingPlanProducts::InvalidRequest, response.body['errors'][0]['message'] unless response.body['errors'].nil?

    return response.body.dig('data', 'sellingPlanGroupAddProducts', 'sellingPlanGroup') 
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[UpdateSellingPlanProducts Failed]: #{e}")
    @error = e
  end
end
