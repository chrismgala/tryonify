# frozen_string_literal: true

class Shopify::MetafieldDefinitions::Update < Shopify::Base
  UPDATE_METAFIELD_DEFINITION_QUERY = <<~QUERY
    mutation metafieldDefinitionUpdate($definition: MetafieldDefinitionUpdateInput!) {
      metafieldDefinitionUpdate(definition: $definition) {
        updatedDefinition {
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
        namespace: "$app:#{@attributes[:namespace]}",
        name: @attributes[:name],
        ownerType: @attributes[:owner_type]
      },
    }

    if @attributes[:access].present?
      variables[:definition][:access] = @attributes[:access]
    end

    response = client.query(query: UPDATE_METAFIELD_DEFINITION_QUERY, variables:)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    unless response.body.dig("data", "metafieldDefinitionUpdate", "userErrors").empty?
      raise response.body.dig("data", "metafieldDefinitionUpdate", "userErrors").map { |error| error["message"] }.join(", ") and return
    end

    response
  rescue StandardError => e
    Rails.logger.error("[#{self.class} Failed]: #{e.message}")
    @error = e
    raise e
  end
end
