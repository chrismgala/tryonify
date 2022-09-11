# frozen_string_literal: true

class SearchOrder
  class InvalidRequest < StandardError; end

  attr_accessor :order, :error

  def initialize(query)
    @order = nil
    @query = query
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = <<~QUERY
      query fetchOrders($first: Int, $query: String) {
        orders(first: $first, query: $query, sortKey: CREATED_AT, reverse: true) {
          edges {
            node {
              id
              legacyResourceId
              name
              createdAt
              cancelledAt
              displayFinancialStatus
              displayFulfillmentStatus
              customer {
                email
              }
              paymentTerms {
                overdue
                paymentSchedules(first: 1) {
                  nodes {
                    dueAt
                  }
                }
              }
              lineItems(first: 50) {
                edges {
                  node {
                    id
                    title
                    variantTitle
                    quantity
                    unfulfilledQuantity
                    discountAllocations {
                      allocatedAmountSet {
                        presentmentMoney {
                          amount
                          currencyCode
                        }
                      }
                    }
                    discountedTotalSet {
                      presentmentMoney {
                        amount
                        currencyCode
                      }
                    }
                    discountedUnitPriceSet {
                      presentmentMoney {
                        amount
                        currencyCode
                      }
                    }
                    sellingPlan {
                      name
                      sellingPlanId
                    }
                    image {
                      url
                    }
                  }
                }
              }
            }
          }
        }
      }
    QUERY

    variables = {
      first: 1,
      query: @query
    }

    response = @client.query(query: query, variables: variables)

    raise SearchOrder::InvalidRequest, response.body.dig('errors', 0, 'message') and return unless response.body['errors'].nil?

    @order = response.body.dig('data', 'orders', 'edges', 0, 'node')
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[SearchOrder Failed]: #{e.message}")
    @error = e.message
  end
end
