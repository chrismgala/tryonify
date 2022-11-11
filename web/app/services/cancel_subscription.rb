# frozen_string_literal: true

class CancelSubscription
  CANCEL_QUERY = <<~QUERY
    mutation appSubscriptionCancel($id: ID!) {
      appSubscriptionCancel(id: $id) {
        userErrors {
          field
          message
        }
      }
    }
  QUERY

  def initialize(subscription_id)
    @subscription_id = subscription_id
    session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
  end

  def call
    query = CANCEL_QUERY
    variables = {
      id: "gid://shopify/AppSubscription/#{@subscription_id}"
    }

    response = @client.query(query:, variables:)

    puts response
  end
end
