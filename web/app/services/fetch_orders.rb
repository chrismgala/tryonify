# frozen_string_literal: true

class FetchOrders
  class InvalidRequest < StandardError; end

  attr_accessor :orders, :error

  def initialize(pagination)
    @orders = []
    @pagination = pagination
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = @pagination[:first] ? next_query : previous_query

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
      raise FetchOrders::InvalidRequest,
        response.body.dig("errors", 0, "message") and return
    end

    @orders = response.body.dig("data", "orders")
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[FetchOrders Failed]: #{e.message}")
    @error = e.message
    raise e
  end

  def next_query
    <<~QUERY
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
                  nodes {
                    dueAt
                  }
                }
              }
              lineItems(first: 10) {
                edges {
                  node {
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
  end

  def previous_query
    <<~QUERY
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
  end
end
