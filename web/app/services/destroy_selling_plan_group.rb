# frozen_string_literal: true

class DestroySellingPlanGroup
  class InvalidRequest < StandardError; end

  attr_accessor :error

  def initialize(id)
    @id = id
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = <<~QUERY
      mutation sellingPlanGroupDelete($id: ID!) {
        sellingPlanGroupDelete(
          id: $id
        ) {
          deletedSellingPlanGroupId
          userErrors {
            field
            message
          }
        }
      }
    QUERY


    variables = {
      id: @id
    }

    response = @client.query(query: query, variables: variables)

    # Raise an error if the query is unsuccessful
    raise DestroySellingPlanGroup::InvalidRequest, response.body.dig('errors', 0, 'message') and return unless response.body['errors'].nil?
  rescue DestroySellingPlanGroup::InvalidRequest, ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[DestroySellingPlanGroup Failed]: #{e}")
    @error = e
  end
end
