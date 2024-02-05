# frozen_string_literal: true

class Shopify::MetafieldDefinitions::Fetch < Shopify::Base
  FETCH_METAFIELD_DEFINITIONS_QUERY = <<~QUERY
    query metafieldDefinitions($namespace: String!, $ownerType: MetafieldOwnerType!, $query: String!) {
      metafieldDefinitions(namespace: $namespace, ownerType: $ownerType, query: $query, first: 100) {
        edges {
          node {
            id
            key
            namespace
            name
            ownerType
            access {
              storefront
            }
          }
        }
      }
    }
  QUERY

  def initialize(namespace:, owner_type:, query: '')
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
    @namespace = namespace
    @owner_type = owner_type
    @query = query
  end

  def call
    variables = {
      namespace: @namespace,
      ownerType: @owner_type,
      query: @query
    }
    response = @client.query(query: FETCH_METAFIELD_DEFINITIONS_QUERY, variables:)

    response
  end
end
