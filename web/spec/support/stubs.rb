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
          id: order_id,
          shippingAddress: {
            address1: "",
          },
          lineItems: {
            edges: [],
          },
        },
      },
    }

    WebMock.stub_request(:post, "https://test.myshopify.com/admin/api/2023-04/graphql.json")
      .with(
        body: "{\"query\":\"query fetchOrder($id: ID!, $after: String) {\\n  order(id: $id) {\\n    ...on Order {\\n      id\\n      createdAt\\n      updatedAt\\n      closedAt\\n      cancelledAt\\n      clientIp\\n      name\\n      displayFinancialStatus\\n      displayFulfillmentStatus\\n      customer {\\n        email\\n      }\\n      note\\n      tags\\n      fullyPaid\\n      totalOutstandingSet {\\n        shopMoney {\\n          amount\\n        }\\n      }\\n      paymentTerms {\\n        paymentSchedules(first: 1) {\\n          edges {\\n            node {\\n              dueAt\\n            }\\n          }\\n        }\\n      }\\n      paymentCollectionDetails {\\n        vaultedPaymentMethods {\\n          id\\n        }\\n      }\\n      lineItems(first: 10, after: $after) {\\n        edges {\\n          node {\\n            id\\n            image {\\n              url\\n            }\\n            quantity\\n            restockable\\n            unfulfilledQuantity\\n            title\\n            variantTitle\\n            sellingPlan {\\n              sellingPlanId\\n            }\\n          }\\n        }\\n        pageInfo {\\n          hasNextPage\\n          endCursor\\n        }\\n      }\\n      totalPriceSet {\\n        shopMoney {\\n          amount\\n        }\\n      }\\n      shippingAddress {\\n        address1\\n        address2\\n        city\\n        country\\n        countryCodeV2\\n        province\\n        provinceCode\\n        zip\\n      }\\n    }\\n  }\\n}\\n\",\"variables\":{\"id\":\"#{order_id}\",\"after\":null}}",
        headers: {
          "Accept" => "application/json",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/json",
          "User-Agent" => /.*/,
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

    WebMock.stub_request(:post, "https://test.myshopify.com/admin/api/2023-04/graphql.json")
      .with(
        body: /orderCreateMandatePayment/,
        headers: {
          "Accept" => "application/json",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/json",
          "User-Agent" => /.*/,
          "X-Shopify-Access-Token" => /.*/,
        }
      )
      .to_return(status: 200, body: response_body.to_json, headers: {})
  end
end
