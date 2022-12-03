# frozen_string_literal: true

require "webmock/rspec"

class Stubs
  def initialize
    payment
  end

  def order(order_id)
    response_body = {
      data: {
        order: {
          legacyResourceId: order_id,
        },
      },
    }

    WebMock.stub_request(:post, "https://test.myshopify.com/admin/api/2022-07/graphql.json")
      .with(
        body: "{\"query\":\"query fetchOrder($id: ID!, $after: String) {\\n  order(id: $id) {\\n    ...on Order {\\n      id\\n      legacyResourceId\\n      createdAt\\n      closedAt\\n      name\\n      displayFinancialStatus\\n      displayFulfillmentStatus\\n      customer {\\n        email\\n      }\\n      note\\n      tags\\n      fullyPaid\\n      totalOutstandingSet {\\n        shopMoney {\\n          amount\\n        }\\n      }\\n      paymentTerms {\\n        paymentSchedules(first: 1) {\\n          edges {\\n            node {\\n              dueAt\\n            }\\n          }\\n        }\\n      }\\n      paymentCollectionDetails {\\n        vaultedPaymentMethods {\\n          id\\n        }\\n      }\\n      lineItems(first: 10, after: $after) {\\n        edges {\\n          node {\\n            id\\n            image {\\n              url\\n            }\\n            merchantEditable\\n            quantity\\n            restockable\\n            unfulfilledQuantity\\n            title\\n            variantTitle\\n            sellingPlan {\\n              sellingPlanId\\n            }\\n          }\\n        }\\n        pageInfo {\\n          hasNextPage\\n          endCursor\\n        }\\n      }\\n      totalPriceSet {\\n        shopMoney {\\n          amount\\n        }\\n      }\\n    }\\n  }\\n}\\n\",\"variables\":{\"id\":\"gid://shopify/Order/#{order_id}\",\"after\":null}}",
        headers: {
          "Accept" => "application/json",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/json",
          "User-Agent" => "ShopifyApp/20.1.1 | Shopify API Library v11.1.0 | Ruby 3.1.2",
          "X-Shopify-Access-Token" => /.*/,
        }
      )
      .to_return(status: 200, body: response_body.to_json, headers: {})
  end

  def payment
    response_body = {
      data: {
        orderCreateMandatePayment: {
          paymentReferenceId: "ABC123",
        },
      },
    }

    WebMock.stub_request(:post, "https://test.myshopify.com/admin/api/2022-07/graphql.json")
      .with(
        body: /orderCreateMandatePayment/,
        headers: {
          "Accept" => "application/json",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/json",
          "User-Agent" => "ShopifyApp/20.1.1 | Shopify API Library v11.1.0 | Ruby 3.1.2",
          "X-Shopify-Access-Token" => /.*/,
        }
      )
      .to_return(status: 200, body: response_body.to_json, headers: {})
  end
end
