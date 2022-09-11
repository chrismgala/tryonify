# frozen_string_literal: true

module EnsureBilling
  class BillingError < StandardError; end

  extend ActiveSupport::Concern

  included do
    before_action :check_billing
    rescue_from BillingError, with: :handle_billing_error
  end

  def check_billing
    @shop = Shop.find_by!(shopify_domain: current_shopify_domain)
    return true unless @shop

    @shop.with_shopify_session do
      service = FetchAppSubscription.new
      subscriptions = service.call

      # Redirect to billing if no active subscription
      unless subscriptions.length > 0
        request_payment
      end
    end
  end

  def request_payment
    service = CreateRecurringCharge.new(
      shopify_domain: @shop.shopify_domain,
      shopify_token: @shop.shopify_token
    )

    plan = Plan.where(active: true).first
    confirmation_url = service.create_charge(plan)

    render("shopify_app/shared/redirect", layout: false,
      locals: { url: confirmation_url, current_shopify_domain: current_shopify_domain })
  end
end