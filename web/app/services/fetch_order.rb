# frozen_string_literal: true

class FetchOrder
  class InvalidRequest < StandardError; end

  attr_accessor :order, :has_selling_plan, :error

  def initialize(id:, after: nil, check_selling_plan: false)
    @id = id
    @after = after
    @check_selling_plan = check_selling_plan
    @order = nil
    @has_selling_plan = false
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
            cancelledAt
            clientIp
            name
            displayFinancialStatus
            displayFulfillmentStatus
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
                  merchantEditable
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
          }
        }
      }
    QUERY

    variables = {
      id: @id,
      after: @after,
    }

    response = @client.query(query:, variables:)

    unless response.body["errors"].nil?
      raise FetchOrder::InvalidRequest,
        response.body.dig("errors", 0, "message") and return
    end

    @order = response.body.dig("data", "order")

    has_selling_plan? if @check_selling_plan
  rescue ActiveRecord::RecordInvalid, StandardError => e
    Rails.logger.error("[FetchOrder Failed]: #{e.message}")
    @error = e.message
    raise e
  end

  private

  # Page through line items looking for selling plan
  def has_selling_plan?
    line_items = @order.dig("lineItems", "edges")
    selling_plan_ids = line_items.select { |x| x.dig("node", "sellingPlan", "sellingPlanId") }
      .map { |x| x.dig("node", "sellingPlan", "sellingPlanId") }

    if selling_plan_ids.length.positive? && SellingPlan.where(shopify_id: selling_plan_ids).any?
      @has_selling_plan = true
    elsif @order.dig("lineItems", "pageInfo", "hasNextPage")
      service = FetchOrder.new(id: @id, after: @order.dig("lineItems", "pageInfo", "endCursor"),
        check_selling_plan: true)
      service.call

      if service.order
        @order = service.order
        has_selling_plan?
      else
        raise "Could not fetch order #{@id}"
      end
    else
      @has_selling_plan = false
    end
  end
end
