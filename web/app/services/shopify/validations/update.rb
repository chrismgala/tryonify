# frozen_string_literal: true

class Shopify::Validations::Update < Shopify::Base
  VALIDATION_UPDATE_QUERY = <<~QUERY
    mutation validationUpdate($id: ID!, $validation: ValidationUpdateInput!) {
      validationUpdate(id: $id, validation: $validation) {
        validation {
          id
          enabled
        }
        userErrors {
          field
          message
        }
      }
    }
  QUERY

  def initialize(id:, validation:)
    @id = id
    @validation = validation
  end

  def call
    variables = { id: @id, validation: @validation }
    response = client.query(query: VALIDATION_UPDATE_QUERY, variables: variables)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    unless response.body.dig("data", "validationUpdate", "userErrors").empty?
      raise response.body.dig("data", "validationUpdate", "userErrors", 0, "message") and return
    end

    response
  end
end
