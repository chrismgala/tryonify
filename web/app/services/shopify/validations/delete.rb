# frozen_string_literal: true

class Shopify::Validations::Delete < Shopify::Base
  VALIDATION_DELETE_QUERY = <<~QUERY
    mutation validationDelete($id: ID!) {
      validationDelete(id: $id) {
        deletedId
        userErrors {
          field
          message
        }
      }
    }
  QUERY

  def initialize(id:)
    @id = id
  end

  def call
    variables = { id: @id }
    response = client.query(query: VALIDATION_DELETE_QUERY, variables:)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    unless response.body.dig("data", "validationDelete", "userErrors").empty?
      raise response.body.dig("data", "validationDelete", "userErrors", 0, "message") and return
    end

    validation = Validation.find_by(shopify_id: @id)
    validation.destroy! if validation

    response
  end
end
