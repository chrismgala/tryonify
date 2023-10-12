# frozen_string_literal: true

# Creates a return on Shopify
# Line items should be include:
#   fullfilmentLineItemId: ID
#   quantity: number
#   returnReason: https://shopify.dev/docs/api/admin-graphql/unstable/enums/ReturnReason


class Shopify::Returns::Create < ApplicationService
  CREATE_RETURN_QUERY = <<~QUERY
    mutation returnCreate(returnInput: ReturnInput!) {
      returnCreate(returnInput: $returnInput) {
        return {
          id
          status
        }
      }
    }
  QUERY

  def initialize(order_id:, line_items:, quantity:, return_reason:, return_reason_note:)
    super()
    @order_id = order_id
    @line_items = line_items
    @quantity = quantity
    @return_reason = return_reason
    @return_reason_note = return_reason_note
  end

  def call
    query = CREATE_RETURN_QUERY
    variables = {
      orderId: @order_id,
      returnLineItems: @line_items,
      notifyCustomer: true
    }

    response = @client.query(query:, variables:)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  rescue StandardError => err
    Rails.logger.error("[#{self.class} id=#{@order_id}]: #{err.message}")
    raise err
  end
end