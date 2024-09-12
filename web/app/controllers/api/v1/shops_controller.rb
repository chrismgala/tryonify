# frozen_string_literal: true

module Api
  module V1
    class ShopsController < AuthenticatedController
      before_action :verify_data

      def show
        current_user
      end

      def update
        current_user

        render_errors(current_user) and return unless current_user.update(shop_params)

        if params[:max_trial_items].to_i != current_user.max_trial_items || params[:validation_enabled] != current_user&.validation&.enabled
          Shopify::MetafieldDefinitions::ConfigureMetafieldDefinitions.call
          Shopify::Validations::ConfigureCartValidation.call(max_trials: params[:max_trial_items].to_i, enable: params[:validation_enabled])

          if current_user.selling_plans.any?
            selling_plans = current_user.selling_plans.pluck(:shopify_id)
            attributes = {
              key: "sellingPlans",
              namespace: "$app:settings",
              ownerId: current_user.shopify_id,
              type: "json",
              value: selling_plans.to_json,
            }
            Shopify::Metafields::Create.call([attributes])
          end
        end

        # TODO: Have tags as a validation metafield
        update_allowed_tags
      end

      private

      def update_allowed_tags
        if params[:allowed_tags] != current_user.get_metafield("allowedTags")&.value&.split(",")
          if params[:allowed_tags].length > 0
            # Fetch the App ID to set as owner of the metafield
            service = FetchAppSubscription.new
            service.call

            raise 'Could not get app' unless service.app

            # Save the allowed tags as a metafield for easy use
            # within app block extensions
            Shopify::Metafields::Create.call([{
              key: "allowedTags",
              namespace: "settings",
              ownerId: service.app['id'],
              type: "single_line_text_field",
              value: params[:allowed_tags].join(","),
            }])
          elsif current_user.get_metafield("allowedTags")
            DeleteMetafield.new.call(current_user.get_metafield("allowedTags").shopify_id)
          end
        end
      end

      def verify_data
        unless current_user.shopify_id.present?
          service = Shopify::Store::Fetch.call
          current_user.shopify_id = service.body.dig('data', 'shop', 'id')
          current_user.save!
        end
      end

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
