# frozen_string_literal: true

class Shopify::Validations::Create < Shopify::Base
  VALIDATION_CREATE_QUERY = <<~QUERY
    mutation validationCreate($validation: ValidationCreateInput!) {
      validationCreate(validation: $validation) {
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

  def initialize(validation:)
    @validation = validation
  end

  def call
    variables = { validation: @validation }
    response = client.query(query: VALIDATION_CREATE_QUERY, variables: variables)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    unless response.body.dig("data", "validationCreate", "userErrors").empty?
      raise response.body.dig("data", "validationCreate", "userErrors", 0, "message") and return
    end

    response
  end
end
