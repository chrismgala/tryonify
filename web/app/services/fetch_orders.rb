# frozen_string_literal: true

class FetchOrders < ApplicationService
  attr_accessor :error

  FETCH_NEXT_ORDERS = <<~QUERY
    query fetchOrders($first: Int, $after: String, $query: String, $sortKey: OrderSortKeys!) {
      orders(first: $first, after: $after, query: $query, sortKey: $sortKey, reverse: true) {
        edges {
          node {
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
              defaultEmailAddress
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
        pageInfo {
          hasPreviousPage
          hasNextPage
          startCursor
          endCursor
        }
      }
    }
  QUERY

  FETCH_PREVIOUS_ORDERS = <<~QUERY
    query fetchOrders($last: Int, $before: String, $query: String) {
      orders(last: $last, before: $before, query: $query, sortKey: CREATED_AT, reverse: true) {
        edges {
          node {
            id
            name
            createdAt
            displayFinancialStatus
            paymentTerms {
              overdue
              paymentSchedules(first: 1) {
                nodes {
                  dueAt
                }
              }
            }
            paymentCollectionDetails {
              vaultedPaymentMethods {
                id
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

  def initialize(pagination)
    super()
    @pagination = pagination
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = @pagination[:first] ? FETCH_NEXT_ORDERS : FETCH_PREVIOUS_ORDERS

    variables = {
      first: @pagination[:first].to_i,
      last: @pagination[:last].to_i,
      before: @pagination[:before],
      after: @pagination[:after],
      query: @pagination[:query],
      sortKey: @pagination[:sortKey] || "CREATED_AT",
    }

    response = @client.query(query:, variables:)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") && return
    end

    response
  rescue => error
    Rails.logger.error("[FetchOrders Failed]: #{error.message}")
    @error = error.message
    raise error
  end
end
