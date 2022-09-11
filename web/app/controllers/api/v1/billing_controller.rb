# frozen_string_literal: true

module Api
  module V1
    class BillingController < AuthenticatedController
      # Confirmation of a charge
      def show
        
      end

      def create
        service = CreateRecurringCharge.new(
          shopify_domain: current_user.shopify_domain,
          shopify_token: current_user.shopify_token
        )

        plan = Plan.where(active: true).first

        render json: service.create_charge(plan)
      end
    end
  end
end