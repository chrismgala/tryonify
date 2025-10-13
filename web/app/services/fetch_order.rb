# frozen_string_literal: true

class FetchOrder < ApplicationService
  attr_accessor :error

  FETCH_ORDER_QUERY = <<~QUERY
    query fetchOrder($id: ID!, $after: String) {
      order(id: $id) {
        id
        createdAt
        updatedAt
        closedAt
        cancelledAt
        clientIp
        name
        displayFinancialStatus
        displayFulfillmentStatus
        customer {
          defaultEmailAddress
        }
        note
        tags
        fullyPaid
        totalOutstandingSet {
          shopMoney {
            amount
          }
        }
        paymentTerms {
          id
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
              id
              image {
                url
              }
              quantity
              restockable
              unfulfilledQuantity
              title
              variantTitle
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
  QUERY

  def initialize(id:, after: nil)
    super()
    @id = id
    @after = after
    @session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
  end

  def call
    variables = {
      id: @id,
      after: @after
    }

    response = @client.query(query: FETCH_ORDER_QUERY, variables:)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[FetchOrder Failed id=#{@id}]: #{e.message}")
    @error = e.message
    raise e
  end
end
