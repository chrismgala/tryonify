# frozen_string_literal: true

class Shopify::Validations::Find < Shopify::Base
  FETCH_VALIDATION_QUERY = <<~QUERY
    query validation($id: ID!) {
      validation(id: $id) {
        id
        enabled
      }
    }
  QUERY

  def initialize(id)
    @id = id
  end

  def call
    variables = {
      id: @id
    }
    response = client.query(query: FETCH_VALIDATION_QUERY, variables:)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  end
end
