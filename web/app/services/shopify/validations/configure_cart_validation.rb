# frozen_string_literal: true

class Shopify::Validations::ConfigureCartValidation < Shopify::Base
  def initialize(max_trials: 3, enable: false)
    @max_trials = max_trials
    @enable = enable
  end

  def call
    shop.with_shopify_session do
      configure_validation
    end
  end

  private

  def configure_validation
    response = Shopify::Validations::Fetch.call
    validations = response.body.dig("data", "validations", "edges")
    configuration = {
      blockOnFailure: true,
      enable: @enable,
      metafields: [{
        key: "maxTrialItems",
        namespace: "$app:settings",
        type: "number_integer",
        value: @max_trials.to_s
      }]
    }

    if validations.any?
      validation = validations.find { |validation| validation.dig("node", "shopifyFunction", "apiType") == "cart_checkout_validation" && validation.dig("node", "shopifyFunction", "app", "apiKey") == ENV["SHOPIFY_API_KEY"] }
      if validation.present?
        response = Shopify::Validations::Update.call(id: validation.dig("node", "id"), validation: configuration)
        shop.update!(max_trial_items: @max_trials, validation_enabled: @enable)
      end
    end
  end
end
