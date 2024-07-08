# frozen_string_literal: true

module Shopify
  class Orders::Cancel < Shopify::Base
    attr_accessor :error

    CANCEL_ORDER_QUERY = <<~QUERY
      mutation OrderCancel(
        $orderId: ID!,
        $notifyCustomer: Boolean,
        $refund: Boolean!, $restock: Boolean!,
        $reason: OrderCancelReason!,
        $staffNote: String
      ) {
        orderCancel(
          orderId: $orderId,
          notifyCustomer: $notifyCustomer,
          refund: $refund,
          restock: $restock,
          reason: $reason,
          staffNote: $staffNote
        ) {
          job {
            id
            done
          }
          orderCancelUserErrors {
            field
            message
            code
          }
        }
      }
    QUERY

    def initialize(order_id:, refund: true, restock: true, reason: "CUSTOMER", staff_note: nil)
      super()
      @order_id = order_id
      @refund = refund
      @restock = restock
      @reason = reason
      @staff_note = staff_note
      @error = nil
    end

    def call
      cancel_order
    rescue StandardError => e
      Rails.logger.error("[#{self.class} Failed]: #{e.message}]")
      raise e
    end

    private

    def cancel_order
      response = client.query(
        query: CANCEL_ORDER_QUERY,
        variables: {
          orderId: @order_id,
          notifyCustomer: true,
          refund: @refund,
          restock: @restock,
          reason: @reason,
          staffNote: @staff_note
        }
      )

      unless response.body['errors'].blank?
        @error = response.body['errors'].map { |error| error['message'] }.join(', ')
        raise StandardError.new, @error
      end

      unless response.body.dig('data', 'orderCancel', 'orderCancelUserErrors').blank?
        @error = response.body.dig('data', 'orderCancel', 'orderCancelUserErrors').map { |error| error['message'] }.join(', ')
        raise StandardError.new, @error
      end

      response
    end
  end
end
