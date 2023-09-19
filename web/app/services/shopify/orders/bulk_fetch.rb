# frozen_string_literal: true

class Shopify::Orders::BulkFetch < Shopify::Base
  def call
    response = Shopify::BulkOperation::Run.call(build_query)
    data = response.body.dig('data', 'bulkOperationRunQuery', 'bulkOperation')

    if data
      bulk_operation = BulkOperation.create(
        shopify_id: data['id'],
        error_code: data['errorCode'],
        status: data['status'].downcase,
        query: data['query'],
        shop: shop,
      )
    end
  end

  private

  def build_query
    period = 30.days.ago
    query = <<~QUERY
      {
        orders(query: "created_at:>=#{period.iso8601} AND status:OPEN") {
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
              shippingAddress {
                address1
                address2
                city
                country
                countryCodeV2
                province
                provinceCode
                zip
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
              returns {
                edges {
                  node {
                    id
                    status
                    returnLineItems {
                      edges {
                        node {
                          id
                          quantity
                          fulfillmentLineItem {
                            lineItem {
                              id
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
              transactions {
                id
                paymentId
                parentTransaction {
                  id
                }
                createdAt
                receiptJson
                kind
                errorCode
                authorizationExpiresAt
                gateway
                status
                amountSet {
                  shopMoney {
                    amount
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