# frozen_string_literal: true

class RemoveSellingPlanProducts
  class InvalidRequest < StandardError; end

  attr_accessor :error

  def initialize(id, product_ids)
    @id = id
    @product_ids = product_ids
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = <<~QUERY
      mutation sellingPlanGroupRemoveProducts($id: ID!, $productIds: [ID!]!) {
        sellingPlanGroupRemoveProducts(id: $id, productIds: $productIds) {
          removedProductIds
          userErrors {
            field
            message
          }
        }
      }
    QUERY

    variables = {
      id: @id,
      productIds: @product_ids
    }

    response = @client.query(query: query, variables: variables)
    return response.body['data']['removedProductIds'] if response.body['errors'].nil?

    raise RemoveSellingPlanProducts::InvalidRequest, response.body['errors'][0]['message']
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[RemoveSellingPlanProducts Failed]: #{e}")
  end
end
