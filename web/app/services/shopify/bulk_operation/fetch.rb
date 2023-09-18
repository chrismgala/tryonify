# Fetch a bulk operation from the Shopify API

class Shopify::BulkOperation::Fetch < Shopify::Base
  BULK_OPERATION_FETCH_QUERY = <<~QUERY
    query fetchBulkOperation($id: ID!) {
      node(id: $id) {
        ... on BulkOperation {
          id
          completedAt
          errorCode
          url
          status
          query
        }
      }
    }
  QUERY

  def initialize(id)
    super()
    @id = id
  end

  def call
    query = BULK_OPERATION_FETCH_QUERY
    variables = {
      id: @id
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