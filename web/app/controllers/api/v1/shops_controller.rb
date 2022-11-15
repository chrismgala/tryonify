# frozen_string_literal: true

module Api
  module V1
    class ShopsController < AuthenticatedController
      def show
        @shop = current_user
      end

      def update
        @shop = current_user

        if @shop.max_trial_items != shop_params[:max_trial_items].to_i
          # Set max trial metafield
          service = CreateMetafield.new({
                                          key: 'maxTrialItems',
                                          namespace: 'settings',
                                          type: 'number_integer',
                                          value: shop_params[:max_trial_items].to_i
                                        })
          service.call
        end

        render_errors @shop and return unless @shop.update(shop_params)
      end

      private

      def shop_params
        params.permit(
          :klaviyo_public_key,
          :klaviyo_private_key,
          :onboarded,
          :return_explainer,
          :allow_automatic_payments,
          :return_period,
          :max_trial_items
        )
      end
    end
  end
end
