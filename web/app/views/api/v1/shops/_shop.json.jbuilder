# frozen_string_literal: true

require "digest"

json.ignore_nil!
json.extract!(shop, :shopify_domain, :klaviyo_public_key, :klaviyo_private_key, :onboarded, :return_explainer,
  :allow_automatic_payments, :return_period, :currency_code, :authorize_transactions, :void_authorizations)
json.slack_token(shop.slack_token.present?)
json.max_trial_items(shop.get_metafield("maxTrialItems")&.value)
json.allowed_tags(shop.get_metafield("allowedTags")&.value&.split(","))
json.key(Digest::MD5.hexdigest("#{shop.id}#{shop.shopify_domain}"))
