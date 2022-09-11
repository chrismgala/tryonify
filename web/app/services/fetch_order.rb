# frozen_string_literal: true

class FetchOrder
  class InvalidRequest < StandardError; end

  attr_accessor :order, :error

  def initialize(id)
    @id = id
    @order = nil
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = <<~QUERY
      query fetchOrder($id: ID!) {
        order(id: $id) {
          ...on Order {
            id
            name
            displayFinancialStatus
            customer {
              email
            }
            note
            paymentTerms {
              paymentSchedules(first: 1) {
                edges {
                  node {
                    dueAt
                  }
                }
              }
            }
            lineItems(first: 20) {
              edges {
                node {
                  sellingPlan {
                    sellingPlanId
                  }
                }
              }
              pageInfo {
                hasNextPage
                endCursor
              }
            }
            totalPriceSet {
              shopMoney {
                amount
              }
            }
          }
        }
      }
    QUERY

    variables = {
      id: @id
    }

    response = @client.query(query: query, variables: variables)

    raise FetchOrder::InvalidRequest, response.body.dig('errors', 0, 'message') and return unless response.body['errors'].nil?

    @order = response.body.dig('data', 'order')
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[FetchOrder Failed]: #{e.message}")
    @error = e.message
  end
end
