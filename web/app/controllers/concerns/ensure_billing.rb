# frozen_string_literal: true

module EnsureBilling
  class BillingError < StandardError; end

  extend ActiveSupport::Concern

  # List of shops that get app for free
  EXCLUDED_FROM_BILLING = ["sa-shashank.myshopify.com", "26910b-2.myshopify.com", "fd4267.myshopify.com"].freeze

  included do
    before_action :check_billing
    rescue_from BillingError, with: :handle_billing_error
  end

  def check_billing
    return if EXCLUDED_FROM_BILLING.include?(current_shopify_domain)

    @shop = Shop.find_by!(shopify_domain: current_shopify_domain)
    return unless @shop

    @shop.with_shopify_session do
      service = FetchAppSubscription.new
      app = service.call

      # Redirect to billing if no active subscription
      request_payment unless app.dig("activeSubscriptions").length > 0
    end
  end

  def request_payment
    service = CreateRecurringCharge.new(
      shopify_domain: @shop.shopify_domain,
      shopify_token: @shop.shopify_token
    )

    plan = Plan.where(active: true).first
    confirmation_url = service.create_charge(plan)

    if confirmation_url
      render("shopify_app/shared/redirect", layout: false,
        locals: { url: confirmation_url, current_shopify_domain: })
    end
  end
end
