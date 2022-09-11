# frozen_string_literal: true

class FetchProducts
  class InvalidRequest < StandardError; end

  attr_accessor :products, :error

  NEXT_PRODUCTS_QUERY = <<~QUERY
    query products($first: Int, $after: String, $query: String) {
      products(first: $first, after: $after, query: $query) {
        edges {
          node {
            id
            title
            images(first: 1) {
              edges {
                node {
                  altText
                  url
                }
              }
            }
            sellingPlanGroups(first: 10) {
              edges {
                node {
                  id
                }
              }
            }
          }
        }
        pageInfo {
          hasPreviousPage
          hasNextPage
          startCursor
          endCursor
        }
      }
    }
  QUERY

  PREVIOUS_PRODUCTS_QUERY = <<~QUERY
    query products($last: Int!, $before: String, $query: String) {
      products(last: $last, before: $before, query: $query) {
        edges {
          node {
            id
            title
            images(first: 1) {
              edges {
                node {
                  altText
                  url
                }
              }
            }
            sellingPlanGroups(first: 10) {
              edges {
                node {
                  id
                }
              }
            }
          }
        }
        pageInfo {
          hasPreviousPage
          hasNextPage
          startCursor
          endCursor
        }
      }
    }
  QUERY

  def initialize(pagination)
    @products = []
    @pagination = pagination
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = @pagination[:last] ? PREVIOUS_PRODUCTS_QUERY : NEXT_PRODUCTS_QUERY

    variables = {
      first: @pagination[:first].to_i,
      last: @pagination[:last].to_i,
      before: @pagination[:before],
      after: @pagination[:after],
      query: @pagination[:query]
    }

    response = @client.query(query: query, variables: variables)

    raise FetchProducts::InvalidRequest, response.body.dig('errors', 0, 'message') and return unless response.body['errors'].nil?

    @products = response.body.dig('data', 'products')
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[FetchProducts Failed]: #{e.message}")
    @error = e.message
  end
end
