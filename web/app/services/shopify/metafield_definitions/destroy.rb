# frozen_string_literal: true

class Shopify::MetafieldDefinitions::Destroy < Shopify::Base
  DESTROY_METAFIELD_DEFINITION_QUERY = <<~QUERY
    mutation metafieldDefinitionDelete($id: ID!, $delete_all: Boolean!) {
      metafieldDefinitionDelete(id: $id, deleteAllAssociatedMetafields: $delete_all) {
        deletedDefinitionId
        userErrors {
          field
          message
        }
      }
    }
  QUERY

  def initialize(id:, delete_all: false)
    @id = id
    @delete_all = delete_all
  end

  def call
    variables = {
      id: @id,
      delete_all: @delete_all
    }

    response = client.query(query: DESTROY_METAFIELD_DEFINITION_QUERY, variables: variables)

    puts response.inspect
  end
end
