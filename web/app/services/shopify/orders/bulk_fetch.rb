# frozen_string_literal: true

class Shopify::Orders::BulkFetch < Shopify::Base
  def call
    response = Shopify::BulkOperation.call(build_query)
    data = response.body.dig('data', 'bulkOperationRunQuery', 'bulkOperation')
    puts response.inspect
    if data
      bulk_operation = BulkOperation.create(
        shopify_id: data['id'],
        error_code: data['errorCode'],
        status: data['status'],
        query: data['query'],
        shop: shop,
      )
    end
  end

  private

  def build_query
    created_at = 60.days.ago

    query = <<~QUERY
      {
        orders(query: "created_at:>=#{created_at}") {
          edges {
            node {
              id
              legacyResourceId
              name
              createdAt
              updatedAt
              closedAt
              cancelledAt
              displayFinancialStatus
              displayFulfillmentStatus
              clientIp
              customer {
                email
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
                overdue
                paymentSchedules {
                  edges {
                    node {
                      id
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
              lineItems {
                edges {
                  node {
                    id
                    title
                    unfulfilledQuantity
                    quantity
                    restockable
                    variantTitle
                    image {
                      url
                    }
                    sellingPlan {
                      sellingPlanId
                    }
                  }
                }
              }
            }
          }
        }
      }
    QUERY
  end
end