# frozen_string_literal: true

module Api
  module V1
    class CheckoutsController < AuthenticatedController
      def index
        checkouts = current_user.checkouts.page(pagination_params[:page])

        payload = {
          results: checkouts,
          pagination: {
            total_pages: checkouts.total_pages,
            current_page: checkouts.current_page,
            next_page: checkouts.next_page,
            prev_page: checkouts.prev_page,
          },
        }

        render(json: payload)
      end

      def create
        checkout = CheckoutCreate.call(params[:id])
        render(json: checkout)
      end

      def bulk_destroy
        checkouts = current_user.checkouts.where(id: params[:ids])
        checkouts.destroy_all
        render(json: { success: true })
      end

      private

      def pagination_params
        params.permit(
          :page,
        )
      end
    end
  end
end
