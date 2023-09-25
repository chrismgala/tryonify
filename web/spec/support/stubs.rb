# frozen_string_literal: true

require "webmock/rspec"

class Stubs
  def initialize
    payment
  end

  def order(order)
    response_body = {
      data: {
        order: {
          id: order.id,
          paymentTerms: {
            paymentSchedules: {
              edges: [
                {
                  node: {
                    dueAt: order.due_date,
                  },
                },
              ],
            },
          },
          paymentCollectionDetails: {
            vaultedPaymentMethods: [
              {
                id: order.mandate_id,
              },
            ],
          },
          customer: {
            email: order.email,
          },
          totalOutstandingSet: {
            shopMoney: {
              amount: order.total_outstanding,
            },
          },
          displayFinancialStatus: order.financial_status,
          fullyPaid: order.fully_paid,
          name: order.name,
          shippingAddress: {
            address1: "",
          },
          lineItems: {
            edges: order.line_items.map do |line_item|
                {
                  node: {
                    id: line_item.shopify_id,
                    image: {
                      url: line_item.image_url
                    },
                    quantity: line_item.quantity,
                    restockable: line_item.restockable,
                    unfulfilledQuantity: line_item.unfulfilled_quantity,
                    title: line_item.title,
                    variantTitle: line_item.variant_title,
                    sellingPlan: {
                      sellingPlanId: line_item.selling_plan.shopify_id
                    }
                  }
                }
            end,
          },
        },
      },
    }

    WebMock.stub_request(:post, "https://test.myshopify.com/admin/api/2023-04/graphql.json")
      .with(
        body: /fetchOrder/,
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

  def capture
    response_body = {
      data: {
        orderCapture: {
          transaction: {
            status: "SUCCESS",
          },
        },
      },
    }

    WebMock.stub_request(:post, "https://test.myshopify.com/admin/api/2023-04/graphql.json")
      .with(
        body: /orderCapture/,
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

  def payment_status_paid
    response_body = {
      data: {
        orderPaymentStatus: {
          status: "PAID",
          errorMessage: nil,
        },
      },
    }.to_json

    WebMock.stub_request(:post, "https://test.myshopify.com/admin/api/2023-04/graphql.json")
      .with(
        body: /fetchPaymentStatus/,
        headers: {
          "Accept" => "application/json",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/json",
          "User-Agent" => /.*/,
          "X-Shopify-Access-Token" => /.*/,
        }
      )
      .to_return(
        status: 200,
        body: response_body,
        headers: {}
      )
  end

  def update_tags
    WebMock.stub_request(:post, "https://test.myshopify.com/admin/api/2023-04/graphql.json")
      .with(
        body: /updateOrder/,
        headers: {
          "Accept" => "application/json",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/json",
          "User-Agent" => /.*/,
          "X-Shopify-Access-Token" => /.*/,
        }
      )
      .to_return(status: 200, body: "", headers: {})
  end

  def create_transaction
    WebMock.stub_request(:post, /transactions\.json/)
      .with(
        body: /.*/,
        headers: {
          "Accept" => "application/json",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/json",
          "User-Agent" => /.*/,
          "X-Shopify-Access-Token" => /.*/,
        }
      )
      .to_return(
        status: 200,
        body: lambda { |request| request.body },
        headers: {}
      )
  end

  def fetch_transactions(transactions = "")
    WebMock.stub_request(:post, "https://test.myshopify.com/admin/api/2023-04/graphql.json")
      .with(
        body: /fetchTransaction/,
        headers: {
          "Accept" => "application/json",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/json",
          "User-Agent" => /.*/,
          "X-Shopify-Access-Token" => /.*/,
        }
      )
      .to_return(status: 200, body: transactions, headers: {})
  end
end
