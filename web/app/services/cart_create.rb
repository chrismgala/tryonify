# frozen_string_literal: true

class CartCreate < ApplicationService
  CREATE_CART_QUERY = <<~QUERY
    mutation cartCreate($input: CartInput!) {
      cartCreate(input: $input) {
        cart {
          id
          checkoutUrl
        }
        userErrors {
          field
          message
        }
      }
    }
  QUERY

  def initialize(line_items:)
    super()
    @line_items = line_items
    session = ShopifyAPI::Context.active_session
    @shop = Shop.find_by(shopify_domain: session.shop)
    @client = ShopifyAPI::Clients::Graphql::Storefront.new(session: session,
      access_token: @shop.storefront_access_token)
  end

  def call
    create_cart
  end

  private

  def create_cart
    variables = {
      input: {
        lines: @line_items,
      },
    }

    response = @client.query(query: CREATE_CART_QUERY, variables: variables)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  end
end
