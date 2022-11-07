# frozen_string_literal: true

class CreateMetafield
  class InvalidRequest < StandardError; end

  attr_accessor :error

  CREATE_METAFIELD_QUERY = <<~QUERY
    mutation metafieldsSet($metafields: [MetafieldsSetInput!]!) {
      metafieldsSet(metafields: $metafields) {
        metafields {
          id
          key
          namespace
          type
          value
        }
        userErrors {
          field
          message
        }
      }
    }
  QUERY

  # attributes - Metafield attributes https://shopify.dev/api/admin-graphql/2022-10/mutations/metafieldDefinitionUpdate
  def initialize(shop, attributes)
    session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
    @shop = shop
    @attributes = attributes
    @error = nil
  end

  def call
    service = FetchAppSubscription.new
    service.call

    return unless service.app

    variables = {
      metafields: [{
        key: @attributes[:key],
        namespace: @attributes[:namespace],
        ownerId: service.app['id'], # App owned metafield
        type: @attributes[:type],
        value: @attributes[:value].to_s
      }]
    }

    response = @client.query(query: CREATE_METAFIELD_QUERY, variables:)

    unless response.body['errors'].nil?
      raise CreateMetafield::InvalidRequest,
            response.body.dig('errors', 0, 'message') and return
    end
  rescue StandardError => e
    Rails.logger.error("[CreateMetafield Failed]: #{e.message}")
    @error = e
    raise e
  end
end
