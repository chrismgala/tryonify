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
  def initialize
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
    @error = nil
  end

  def call(attributes)
    service = FetchAppSubscription.new
    service.call

    return unless service.app

    variables = {
      metafields: [{
        key: attributes[:key],
        namespace: "$app:#{attributes[:namespace]}",
        ownerId: attributes[:ownerId],
        type: attributes[:type],
        value: attributes[:value].to_s,
      }],
    }

    response = @client.query(query: CREATE_METAFIELD_QUERY, variables:)

    unless response.body["errors"].nil?
      raise CreateMetafield::InvalidRequest,
        response.body.dig("errors", 0, "message") and return
    end

    shop = Shop.find_by!(shopify_domain: @session.shop)
    metafield = Metafield.find_or_create_by(shop_id: shop.id, key: attributes[:key],
      namespace: attributes[:namespace]) do |metafield|
      metafield.shop_id = shop.id
      metafield.key = attributes[:key]
      metafield.namespace = attributes[:namespace]
    end
    metafield.shopify_id = response.body.dig("data", "metafieldsSet", "metafields", 0, "id")
    metafield.value = attributes[:value]
    metafield.save!
  rescue StandardError => e
    Rails.logger.error("[CreateMetafield Failed]: #{e.message}")
    @error = e
    raise e
  end
end
