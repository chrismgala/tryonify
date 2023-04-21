# frozen_string_literal: true

class StorefrontAccessTokenCreate < ApplicationService
  CREATE_STOREFRONT_ACCESS_TOKEN_QUERY = <<~QUERY
    mutation delegateAccessTokenCreate($input: DelegateAccessTokenInput!) {
      delegateAccessTokenCreate(input: $input) {
        delegateAccessToken {
          accessToken
        }
        userErrors{
          field
          message
        }
      }
    }
  QUERY

  def initialize
    super()
    session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
  end

  def call
    create_storefront_access_token
  end

  private

  def create_storefront_access_token
    variables = {
      input: {
        delegateAccessScope: "unauthenticated_read_checkouts, unauthenticated_write_checkouts",
      },
    }

    response = @client.query(query: CREATE_STOREFRONT_ACCESS_TOKEN_QUERY, variables: variables)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  end
end
