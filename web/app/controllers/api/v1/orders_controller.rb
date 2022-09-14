# frozen_string_literal: true

module Api
  module V1
    class OrdersController < AuthenticatedController
      def index
        orders = []

        case pagination_params[:query]
        when 'overdue'
          orders = current_user.orders.payment_due.order(shopify_created_at: :desc)
        when 'pending'
          orders = current_user.orders.pending.order(shopify_created_at: :desc)
        else
          orders = current_user.orders.order(shopify_created_at: :desc)
        end

        render json: orders
      end

      private

      def pagination_params
        params.permit(
          :query,
          :first,
          :last,
          :before,
          :after
        )
      end
    end
  end
end