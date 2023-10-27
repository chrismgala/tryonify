# frozen_string_literal: true

# Request a return on Shopify
# Line items should be include:
#   fullfilmentLineItemId: ID
#   quantity: number
#   returnReason: https://shopify.dev/docs/api/admin-graphql/unstable/enums/ReturnReason


class Shopify::Returns::Request < Shopify::Base
  REQUEST_RETURN_QUERY = <<~QUERY
    mutation returnRequest($input: ReturnRequestInput!) {
      returnRequest(input: $input) {
        return {
          id
          status
          returnLineItems(first: 20) {
            edges {
              node {
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
  QUERY

  def initialize(order_id:, line_items:, return_reason: 'UNWANTED', customer_note: '')
    super()
    @order_id = order_id
    @line_items = line_items
    @return_reason = return_reason
    @customer_note = customer_note
  end

  def call
    query = REQUEST_RETURN_QUERY
    return_line_items = @line_items.map do |line_item|
      {
        fulfillmentLineItemId: line_item[:fulfillment_line_item_id],
        quantity: line_item[:quantity].to_i,
        returnReason: @return_reason,
        customerNote: @customer_note
      }
    end

    variables = {
      input: {
        orderId: @order_id,
        returnLineItems: return_line_items
      }
    }

    response = client.query(query:, variables:)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  rescue StandardError => err
    Rails.logger.error("[#{self.class} id=#{@order_id}]: #{err.message}")
    raise err
  end
end