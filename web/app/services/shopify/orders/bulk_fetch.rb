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
    returns = ''
    if shop.access_scopes.include?('write_returns')
      returns = '
        returns {
          edges {
            node {
              id
              status
              returnLineItems {
                edges {
                  node {
                    ... on ReturnLineItem {
                      id
                      quantity
                      fulfillmentLineItem {
                        id
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
        }'
    end

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
                defaultEmailAddress {
                  emailAddress
                }
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
              #{returns}
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