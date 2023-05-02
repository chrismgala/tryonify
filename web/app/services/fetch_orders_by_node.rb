# frozen_string_literal: true

class FetchOrdersByNode
  class InvalidRequest < StandardError; end

  attr_accessor :orders, :error

  QUERY_ORDER_NODES = <<~QUERY
    query fetchOrders($ids: [ID!]!) {
      nodes(ids: $ids) {
        ... on Order {
          id
          legacyResourceId
          name
          createdAt
          updatedAt
          closedAt
          cancelledAt
          displayFinancialStatus
          displayFulfillmentStatus
          clientIp
          customer {
            email
          }
          note
          tags
          fullyPaid
          totalOutstandingSet {
            shopMoney {
              amount
            }
          }
          paymentTerms {
            overdue
            paymentSchedules(first: 1) {
              edges {
                node {
                  dueAt
                }
              }
            }
          }
          paymentCollectionDetails {
            vaultedPaymentMethods {
              id
            }
          }
          lineItems(first: 10) {
            edges {
              node {
                id
                title
                unfulfilledQuantity
                quantity
                restockable
                variantTitle
                image {
                  url
                }
                sellingPlan {
                  sellingPlanId
                }
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      }
    }
  QUERY

  def initialize(ids)
    @ids = ids
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    variables = {
      ids: @ids,
    }

    response = @client.query(query: QUERY_ORDER_NODES, variables:)

    unless response.body["errors"].nil?
      raise FetchOrdersByNode::InvalidRequest,
        response.body.dig("errors", 0, "message") and return
    end

    @orders = response.body.dig("data", "nodes")
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[FetchOrdersByNode Failed]: #{e.message}")
    @error = e.message
    raise e
  end
end
