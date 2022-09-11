# frozen_string_literal: true

class DestroySellingPlan
  def initialize(shop, id)
    @shop = shop
    @id = id
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = <<~QUERY
      mutation sellingPlanGroupDelete($id: ID!) {
        sellingPlanGroupDelete(id: $id) {
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
    Rails.logger.debug response.inspect
    response.body['data']['sellingPlanGroups']
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[DestroySellingPlan Failed]: #{e}")
  end
end
