# frozen_string_literal: true

class Shopify::Orders::BulkFetch < Shopify::Base
  def call
    response = Shopify::BulkOperation.call(query: build_query)
    data = response.body.dig('data', 'bulkOperation')

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
        orders(query: created_at:>=#{created_at}) {
          ... on Order {
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
    QUERY
  end
end