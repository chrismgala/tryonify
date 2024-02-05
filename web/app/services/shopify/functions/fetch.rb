# frozen_string_literal: true

class Shopify::Functions::Fetch < Shopify::Base
  FETCH_SHOPIFY_FUNCTIONS_QUERY = <<~QUERY
    query shopifyFunctions(apiType: String!) {
      shopifyFunctions(apiType: $apiType, first: 100) {
        edges {
          node {
            id
            app {
              apiKey
            }
          }
        }
      }
    }
  QUERY

  def initialize(apiType: "cart_checkout_validation")
    @apiType = apiType
  end

  def call
    variables = { apiType: @apiType }
    response = client.query(query: FETCH_SHOPIFY_FUNCTIONS_QUERY, variables:)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  end
end
