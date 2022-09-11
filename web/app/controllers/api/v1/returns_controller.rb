# frozen_string_literal: true

module Api
  module V1
    class ReturnsController < AuthenticatedController
      def index
        @orders = current_user.orders.pending_returns

        render json: @orders, include: :returns
      end

      def update
        order = Order.find(params[:id])

        if Return.where(order_id: params[:id]).update_all(active: false)
          render json: order
        else
          render_errors order
        end
      end

      private

      def return_params
        params.permit(
          :active
        )
      end
    end
  end
end