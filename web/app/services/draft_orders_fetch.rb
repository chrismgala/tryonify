# frozen_string_literal: true

class DraftOrdersFetch < ApplicationService
  FETCH_NEXT_DRAFT_ORDERS_QUERY = <<~QUERY
    query draftOrders($after: String, $query: String) {
      draftOrders(first: 20, after: $after, query: $query) {
        edges {
          node {
            id
            name
            createdAt
            customer {
              id
              defaultEmailAddress
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

  FETCH_PREVIOUS_DRAFT_ORDERS_QUERY = <<~QUERY
    query draftOrders($before: String, $query: String) {
      draftOrders(first: 20, before: $before, query: $query) {
        edges {
          node {
            id
            name
            createdAt
            customer {
              id
              email
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
    @error = nil
    session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
  end

  def call
    fetch_draft_orders
  end

  private

  def fetch_draft_orders
    query = @pagination[:before] ? FETCH_PREVIOUS_DRAFT_ORDERS_QUERY : FETCH_NEXT_DRAFT_ORDERS_QUERY
    variables = {
      after: @pagination[:after],
      before: @pagination[:before],
      query: @pagination[:query],
    }
    response = @client.query(query:, variables:)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  end
end
