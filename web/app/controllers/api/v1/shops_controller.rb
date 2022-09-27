# frozen_string_literal: true

module Api
  module V1
    class ShopsController < AuthenticatedController
      def show
        @shop = current_user
      end

      def update
        @shop = current_user
        render_errors @shop and return unless @shop.update(shop_params)
      end

      private

      def shop_params
        params.permit(
          :klaviyo_public_key,
          :klaviyo_private_key,
          :onboarded,
          :return_explainer,
          :allow_automatic_payments
        )
      end
    end
  end
end
