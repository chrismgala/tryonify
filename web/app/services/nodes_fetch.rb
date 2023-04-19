# frozen_string_literal: true

class NodesFetch < ApplicationService
  QUERY_NODES = <<~QUERY
    query($ids: [ID!]!) {
      nodes(ids: $ids) {
        ... on ProductVariant {
          id
          legacyResourceId
          sellingPlanGroups(first: 10) {
            edges {
              node {
                id
                sellingPlans(first: 1) {
                  edges {
                    node {
                      id
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  QUERY

  def initialize(ids)
    super()
    @ids = ids
    session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
  end

  def call
    fetch_nodes
  end

  private

  def fetch_nodes
    variables = {
      ids: @ids,
    }

    response = @client.query(query: QUERY_NODES, variables: variables)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  end
end
