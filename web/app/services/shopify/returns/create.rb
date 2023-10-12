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
        }
      }
    }
  QUERY

  def initialize(order_id:, line_items:)
    super()
    @order_id = order_id
    @line_items = line_items
    @return_reason = 'UNWANTED'
    @return_reason_note = ''
  end

  def call
    query = CREATE_RETURN_QUERY

    @line_items.each do |line_item|
      line_item[:returnReason] = @return_reason
      line_item[:returnReasonNote] = @return_reason_note
    end

    variables = {
      returnInput: {
        orderId: @order_id,
        returnLineItems: @line_items,
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