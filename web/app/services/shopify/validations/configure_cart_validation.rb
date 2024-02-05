# frozen_string_literal: true

class Shopify::Validations::ConfigureCartValidation < Shopify::Base
  def initialize(max_trials: 3, enable: false)
    @max_trials = max_trials
    @enable = enable
  end

  def call
    verify_shop_id
    set_max_trials_metafield
    configure_validation
  rescue StandardError => e
    raise e
  end

  private

  def verify_shop_id
    unless shop.shopify_id.present?
      shopify_shop = ShopifyAPI::Shop.all.first
      shop.shopify_id = "gid://shopify/Shop/#{shopify_shop.id}"
      raise 'Shop missing Shopify ID' unless shop.save!
    end
  end

  def set_max_trials_metafield
    Shopify::Metafields::Create.call([{
      key: "maxTrialItems",
      namespace: "$app:settings",
      ownerId: shop.shopify_id,
      type: "number_integer",
      value: @max_trials
    }])
  end

  def configure_validation
    response = Shopify::Validations::Fetch.call
    validations = response.body.dig("data", "validations", "edges")
    configuration = {
      blockOnFailure: true,
      enable: @enable,
    }

    if validations.any?
      shopify_validation = validations.find { |validation| validation.dig("node", "shopifyFunction", "apiType") == "cart_checkout_validation" && validation.dig("node", "shopifyFunction", "app", "apiKey") == ENV["SHOPIFY_API_KEY"] }
      if shopify_validation.present?
        response = Shopify::Validations::Update.call(id: shopify_validation.dig("node", "id"), validation: configuration)
        validation = Validation.find_or_create_by!(shop: shop, shopify_id: response.body.dig("data", "validationUpdate", "validation", "id"))
        validation.enabled = response.body.dig("data", "validationUpdate", "validation", "enabled")
        validation.save!
        shop.update!(max_trial_items: @max_trials)
      end
    end
  end
end
