# frozen_string_literal: true

class Shopify::MetafieldDefinitions::ConfigureMetafieldDefinitions < Shopify::Base
  MAX_TRAILS_ITEMS_ATTRIBUTES = {
    key: "maxTrialItems",
    namespace: "$app:settings",
    name: "Max Trial Items",
    owner_type: "SHOP",
    type: "number_integer",
    access: {
      "admin": "MERCHANT_READ",
      "storefront": "PUBLIC_READ"
    }
  }

  SELLING_PLANS_ATTRIBUTES = {
    key: "sellingPlans",
    namespace: "$app:settings",
    name: "Selling Plans",
    owner_type: "SHOP",
    type: "json",
    access: {
      "admin": "MERCHANT_READ",
      "storefront": "PUBLIC_READ"
    }
  }

  def call
    existing_metafields = fetch_existing_definitions
    max_trial_metafield = find_metafield("maxTrialItems", existing_metafields)
    selling_plans_metafield = find_metafield("sellingPlans", existing_metafields)
    configure_metafield(metafield: max_trial_metafield, attributes: MAX_TRAILS_ITEMS_ATTRIBUTES)
    configure_metafield(metafield: selling_plans_metafield, attributes: SELLING_PLANS_ATTRIBUTES)
  end

  private

  def fetch_existing_definitions
    Shopify::MetafieldDefinitions::Fetch.call(namespace: "$app:settings", owner_type: "SHOP")
  end

  def find_metafield(key, data)
    node = data.body.dig("data", "metafieldDefinitions", "edges")&.find { |edge| edge["node"]["key"] == key }
    node ? node["node"] : nil
  end

  def configure_metafield(metafield:, attributes:)
    if metafield
      unless metafield.dig('access', 'storefront') == 'PUBLIC_READ'
        attributes.delete :type
        Shopify::MetafieldDefinitions::Update.call(attributes)
      end
    else
      Shopify::MetafieldDefinitions::Create.call(attributes)
    end
  end
end
