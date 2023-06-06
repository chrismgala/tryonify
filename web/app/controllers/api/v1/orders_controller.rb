# frozen_string_literal: true

module Api
  module V1
    class OrdersController < AuthenticatedController
      def index
        orders = case pagination_params[:status]
        when "overdue"
          current_user.orders.includes(:returns).payment_due.order(shopify_created_at: :desc)
        when "pending"
          current_user.orders.includes(:returns).pending.order(shopify_created_at: :desc)
        when "failed_payments"
          current_user.orders.includes(:returns).failed_payments.order(shopify_created_at: :desc)
        when "returns"
          current_user.orders.includes(:returns).pending_returns.order(shopify_created_at: :desc)
        else
          current_user.orders.includes(:returns).order(shopify_created_at: :desc)
        end

        paginated_orders = orders.search(params[:query]).page(pagination_params[:page])

        payload = {
          results: paginated_orders,
          pagination: {
            total_pages: paginated_orders.total_pages,
            current_page: paginated_orders.current_page,
            next_page: paginated_orders.next_page,
            prev_page: paginated_orders.prev_page,
          },
        }

        render(json: payload, include: :returns)
      end

      def show
        order = Order.find(params[:id])

        if order.line_items.length.zero?
          graphql_order = FetchOrder.call(id: order.shopify_id)
          built_order = OrderBuild.call(shop_id: order.shop_id, data: graphql_order.body.dig("data", "order"))
          OrderUpdate.call(order_attributes: built_order, order:)
          order.reload
        end

        # Check whether the user can view this order
        render_errors(:unauthorized) unless current_user.id == order.shop_id
        render(json: { order:, returns: order.returns }, include: [:line_items])
      end

      private

      def pagination_params
        params.permit(
          :query,
          :status,
          :page,
        )
      end
    end
  end
end
