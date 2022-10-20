# frozen_string_literal: true

class FetchOrder
  class InvalidRequest < StandardError; end

  attr_accessor :order, :error

  def initialize(id, after = nil)
    @id = id
    @after = after
    @order = nil
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    query = <<~QUERY
      query fetchOrder($id: ID!, $after: String) {
        order(id: $id) {
          ...on Order {
            id
            legacyResourceId
            createdAt
            closedAt
            name
            displayFinancialStatus
            displayFulfillmentStatus
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
            paymentCollectionDetails {
              vaultedPaymentMethods {
                id
              }
            }
            lineItems(first: 10, after: $after) {
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
      id: @id,
      after: @after
    }

    response = @client.query(query:, variables:)

    unless response.body['errors'].nil?
      raise FetchOrder::InvalidRequest,
            response.body.dig('errors', 0, 'message') and return
    end

    @order = response.body.dig('data', 'order')
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[FetchOrder Failed]: #{e.message}")
    @error = e.message
    raise e
  end
end
