# frozen_string_literal: true

# Creates a return on Shopify
# Line items should be include:
#   fullfilmentLineItemId: ID
#   quantity: number
#   returnReason: https://shopify.dev/docs/api/admin-graphql/unstable/enums/ReturnReason


class Shopify::Returns::Create < Shopify::Base
  CREATE_RETURN_QUERY = <<~QUERY
    mutation returnCreate($returnInput: ReturnInput!) {
      returnCreate(returnInput: $returnInput) {
        return {
          id
          status
          returnLineItems(first: 20) {
            edges {
              node {
                id
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

  def initialize(order_id:, line_items:, return_reason: 'UNWANTED', return_reason_note: '')
    super()
    @order_id = order_id
    @line_items = line_items
    @return_reason = return_reason
    @return_reason_note = return_reason_note
  end

  def call
    query = CREATE_RETURN_QUERY
    return_line_items = @line_items.map do |line_item|
      {
        fulfillmentLineItemId: line_item[:fulfillment_line_item_id],
        quantity: line_item[:quantity].to_i,
        returnReason: @return_reason,
        returnReasonNote: @return_reason_note
      }
    end

    variables = {
      returnInput: {
        orderId: @order_id,
        returnLineItems: return_line_items,
        notifyCustomer: true
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