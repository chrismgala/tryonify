# frozen_string_literal: true

class Shopify::MetafieldDefinitions::Create < Shopify::Base
  CREATE_METAFIELD_DEFINITION_QUERY = <<~QUERY
    mutation metafieldDefinitionCreate($definition: MetafieldDefinitionInput!) {
      metafieldDefinitionCreate(definition: $definition) {
        createdDefinition {
          id
          key
          namespace
        }
        userErrors {
          field
          message
        }
      }
    }
  QUERY

  def initialize(attributes)
    @attributes = attributes
  end

  def call
    variables = {
      definition: {
        key: @attributes[:key],
        namespace: @attributes[:namespace],
        name: @attributes[:name],
        ownerType: @attributes[:owner_type],
        type: @attributes[:type]
      },
    }

    if @attributes[:access].present?
      variables[:definition][:access] = @attributes[:access]
    end

    response = client.query(query: CREATE_METAFIELD_DEFINITION_QUERY, variables:)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    unless response.body.dig("data", "metafieldDefinitionCreate", "userErrors").empty?
      raise response.body.dig("data", "metafieldDefinitionCreate", "userErrors").map { |error| error["message"] }.join(", ") and return
    end

    response
  rescue StandardError => e
    Rails.logger.error("[CreateMetafieldDefinition Failed]: #{e.message}")
    @error = e
    raise e
  end
end
