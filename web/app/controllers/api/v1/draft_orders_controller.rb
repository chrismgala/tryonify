# frozen_string_literal: true

module Api
  module V1
    class DraftOrdersController < AuthenticatedController
      def index
        service = DraftOrdersFetch.call(pagination_params)
        render(json: service.body.dig("data", "draftOrders"))
      end

      private

      def pagination_params
        params.permit(
          :query,
          :before,
          :after,
        )
      end
    end
  end
end
