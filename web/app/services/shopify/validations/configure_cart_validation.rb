# frozen_string_literal: true

class Shopify::Validations::ConfigureCartValidation < Shopify::Base
  def initialize(max_trials: 3, enable: false)
    @max_trials = max_trials
    @enable = enable
  end

  def call
    set_app_id_metafield
    set_max_trials_metafield
    configure_validation
  rescue StandardError => e
    raise e
  end

  private

  def set_app_id_metafield
    # Set app metafield
    service = FetchAppSubscription.new
    service.call

    raise 'Could not get app' unless service.app

    Shopify::Metafields::Create.call([{
      key: "appId",
      namespace: "settings",
      ownerId: service.app['id'],
      type: "string",
      value: service.app.dig('app', 'id').split('/').last
    }])
  end

  def set_max_trials_metafield
    Shopify::Metafields::Create.call([{
      key: "maxTrialItems",
      namespace: "$app:settings",
      ownerId: shop.shopify_id,
      type: "number_integer",
      value: @max_trials
    }])
    shop.update!(max_trial_items: @max_trials)
  end

  def configure_validation
    configuration = {
      blockOnFailure: true,
      enable: @enable,
    }

    find_existing_validations unless shop.validation.present?

    if shop.validation.present?
      update_validation(configuration)
    else
      create_validation(configuration)
    end
  end

  def update_validation(configuration)
    response = Shopify::Validations::Update.call(id: shop.validation.shopify_id, validation: configuration)
    shopify_validation = response.body.dig("data", "validationUpdate", "validation")
    shop.validation.update!(enabled: shopify_validation["enabled"])
  end

  def create_validation(configuration)
    shopify_function_id = find_shopify_function_id

    raise "Could not find Shopify function" unless shopify_function_id

    configuration[:functionId] = shopify_function_id

    response = Shopify::Validations::Create.call(validation: configuration)
    shopify_validation = response.body.dig("data", "validationCreate", "validation")
    Validation.create!(shop: shop, shopify_id: shopify_validation["id"], enabled: shopify_validation["enabled"])
  end

  def find_shopify_function_id
    response = Shopify::Functions::Fetch.call
    functions = response.body.dig("data", "shopifyFunctions", "edges")
    app_function = functions.find { |function| function.dig("node", "app", "apiKey") == ENV["SHOPIFY_API_KEY"] }
    app_function.dig("node", "id")
  end

  def find_existing_validations
    response = Shopify::Validations::Fetch.call
    validations = response.body.dig("data", "validations", "edges")

    return nil unless validations.any?

    shopify_validation = validations.find { |validation| validation.dig("node", "shopifyFunction", "apiType") == "cart_checkout_validation" && validation.dig("node", "shopifyFunction", "app", "apiKey") == ENV["SHOPIFY_API_KEY"] }
    if shopify_validation.present?
      Validation.create!(shop: shop, shopify_id: shopify_validation.dig("node", "id"), enabled: shopify_validation.dig("node", "enabled"))
    else
      nil
    end
  end
end
