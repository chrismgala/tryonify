# Performs a bulk operation on the Shopify API
# Accepts a GraphQL query string for any Shopify resource

class Shopify::BulkOperation < ApplicationService
  BULK_OPERATION_QUERY = <<~QUERY
    mutation bulkOperationRunQuery($query: String!) {
      bulkOperationRunQuery(query: $query) {
        bulkOperation {
          id
          completedAt
          errorCode
          url
          status
          query
        }
        userErrors {
          field
          message
        }
      }
    }
  QUERY

  def initialize(query)
    @query = query
  end

  def call
    query = BULK_OPERATION_QUERY
    variables = {
      query: @query
    }

    response = client.query(query:, variables:)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  rescue => err
    Rails.logger.error("[#{self.class} Failed]: #{err.message}")
    raise err
  end
end