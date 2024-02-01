# frozen_string_literal: true

module Api
  module V1
    class ShopsController < AuthenticatedController
      def show
        @shop = current_user
      end

      def update
        @shop = current_user

        render_errors(@shop) and return unless @shop.update(shop_params)

        if params[:max_trial_items].to_i != @shop.max_trial_items || params[:validation_enabled] != @shop.validation_enabled
          Shopify::Validations::ConfigureCartValidation.call(max_trials: params[:max_trial_items].to_i, enable: params[:validation_enabled])
        end

        # TODO: Have tags as a validation metafield
        if params[:allowed_tags] != @shop.get_metafield("allowedTags")&.value&.split(",")
          if params[:allowed_tags].length > 0
            service.call({
              key: "allowedTags",
              namespace: "settings",
              type: "single_line_text_field",
              value: params[:allowed_tags].join(","),
            })
          elsif @shop.get_metafield("allowedTags")
            DeleteMetafield.new.call(@shop.get_metafield("allowedTags").shopify_id)
          end
        end
      end

      private

      def shop_params
        params.require(:shop).permit(
          :klaviyo_public_key,
          :klaviyo_private_key,
          :onboarded,
          :return_explainer,
          :allow_automatic_payments,
          :return_period,
          :authorize_transactions,
          :void_authorizations,
          :reauthorize_paypal,
          :reauthorize_shopify_payments,
          :cancel_prepaid_cards
        )
      end
    end
  end
end
