# frozen_string_literal: true

require "digest"

json.ignore_nil!
json.extract!(shop, :id, :shopify_domain, :klaviyo_public_key, :klaviyo_private_key, :onboarded, :return_explainer,
  :allow_automatic_payments, :return_period, :currency_code, :cancel_prepaid_cards, :authorize_transactions, :reauthorize_paypal,
  :max_trial_items, :reauthorize_shopify_payments, :void_authorizations)
json.slack_token(shop.slack_token.present?)
json.allowed_tags(shop.get_metafield("allowedTags")&.value&.split(","))
json.key(Digest::MD5.hexdigest("#{shop.id}#{shop.shopify_domain}"))
