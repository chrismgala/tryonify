# frozen_string_literal: true

class DeleteMetafield
  class InvalidRequest < StandardError; end

  attr_accessor :error

  DELETE_METAFIELD_QUERY = <<~QUERY
    mutation metafieldDelete($input: MetafieldDeleteInput!) {
      metafieldDelete(input: $input) {
        deletedId
        userErrors {
          field
          message
        }
      }
    }
  QUERY

  # attributes - Metafield attributes https://shopify.dev/api/admin-graphql/2022-10/mutations/metafieldDefinitionUpdate
  def initialize
    session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
    @error = nil
  end

  def call(id)
    service = FetchAppSubscription.new
    service.call

    return unless service.app

    variables = {
      input: {
        id:,
      },
    }

    response = @client.query(query: DELETE_METAFIELD_QUERY, variables:)

    unless response.body["errors"].nil?
      raise DeleteMetafield::InvalidRequest,
        response.body.dig("errors", 0, "message") and return
    end

    metafield = Metafield.find_by!(shopify_id: id)
    metafield.destroy!
  rescue StandardError => e
    Rails.logger.error("[DeleteMetafield Failed]: #{e.message}")
    @error = e
    raise e
  end
end
