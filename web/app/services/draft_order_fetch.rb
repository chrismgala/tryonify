# frozen_string_literal: true

class DraftOrderFetch < ApplicationService
  FETCH_DRAFT_ORDER_QUERY = <<~QUERY
    query($id: ID!) {
      draftOrder(id: $id) {
        id
        name
        lineItems(first: 20) {
          edges {
            node {
              id
              quantity
              variant {
                ... on ProductVariant {
                  id
                  legacyResourceId
                }
              }
            }
          }
        }
      }
    }
  QUERY

  def initialize(id)
    super()
    @id = id
    session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
  end

  def call
    fetch_draft_order
  end

  private

  def fetch_draft_order
    response = @client.query(query: FETCH_DRAFT_ORDER_QUERY, variables: { id: @id })

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  end
end
