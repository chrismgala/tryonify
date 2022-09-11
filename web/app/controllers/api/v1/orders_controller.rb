# frozen_string_literal: true

module Api
  module V1
    class OrdersController < AuthenticatedController
      def index
        orders = []

        case pagination_params[:query]
        when 'overdue'
          orders = current_user.orders.payment_due
        when 'pending'
          orders = current_user.orders.pending
        else
          orders = current_user.orders
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