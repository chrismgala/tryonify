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
      query: @pagination[:query]
    }

    response = @client.query(query: query, variables: variables)

    raise FetchOrders::InvalidRequest, response.body.dig('errors', 0, 'message') and return unless response.body['errors'].nil?

    @orders = response.body.dig('data', 'orders')
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[FetchOrders Failed]: #{e.message}")
    @error = e.message
  end

  def next_query
    <<~QUERY
      query fetchOrders($first: Int, $after: String, $query: String) {
        orders(first: $first, after: $after, query: $query, sortKey: CREATED_AT, reverse: true) {
          edges {
            node {
              id
              legacyResourceId
              name
              createdAt
              displayFinancialStatus
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
