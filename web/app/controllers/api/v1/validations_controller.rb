# frozen_string_literal: true

module Api
  module V1
    class ValidationsController < AuthenticatedController
      def index
        validation = current_user.validation

        raise ActiveRecord::RecordNotFound unless validation.present?

        shopify_validation = Shopify::Validations::Find.call(validation.shopify_id)

        render json: {
          enabled: shopify_validation.body.dig("data", "validation", "enabled")
        }
      end
    end
  end
end
