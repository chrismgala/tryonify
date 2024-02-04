# frozen_string_literal: true

class Shopify::Metafields::Create < Shopify::Base
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

  def initialize(metafields)
    @metafields = metafields
  end

  def call
    variables = {
      metafields: @metafields.map do |metafield|
        {
          key: metafield[:key],
          namespace: metafield[:namespace],
          ownerId: metafield[:ownerId],
          type: metafield[:type],
          value: metafield[:value].to_s
        }
      end
    }

    response = client.query(query: CREATE_METAFIELD_QUERY, variables:)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    if response.body.dig("data", "metafieldsSet", "userErrors").any?
      raise response.body.dig("data", "metafieldsSet", "userErrors").map { |error| error["message"] }.join(", ") and return
    end

    response.body.dig('data', 'metafieldsSet', 'metafields').each do |shopify_metafield|
      metafield = Metafield.find_or_create_by!(
        shop_id: shop.id,
        key: shopify_metafield.dig("key"),
        namespace: shopify_metafield.dig("namespace")
      ) do |metafield|
        metafield.shopify_id = shopify_metafield.dig("id")
      end
      metafield.value = shopify_metafield.dig("value")
      metafield.save!
    end
  rescue StandardError => e
    Rails.logger.error("[CreateMetafield Failed]: #{e.message}")
    raise e
  end
end
