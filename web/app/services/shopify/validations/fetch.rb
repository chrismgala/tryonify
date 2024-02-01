# frozen_string_literal: true

class Shopify::Validations::Fetch < Shopify::Base
  FETCH_VALIDATIONS_QUERY = <<~QUERY
    query validations {
      validations(first: 100) {
        edges {
          node {
            id
            shopifyFunction {
              apiType
              app {
                apiKey
              }
            }
          }
        }
      }
    }
  QUERY

  def initialize
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    response = @client.query(query: FETCH_VALIDATIONS_QUERY)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  end
end
