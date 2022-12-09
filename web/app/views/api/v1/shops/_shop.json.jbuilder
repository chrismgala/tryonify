# frozen_string_literal: true

require "digest"

json.ignore_nil!
json.extract!(shop, :shopify_domain, :klaviyo_public_key, :klaviyo_private_key, :onboarded, :return_explainer,
  :allow_automatic_payments, :return_period, :max_trial_items)
json.slack_token(shop.slack_token.present?)
json.key(Digest::MD5.hexdigest("#{shop.id}#{shop.shopify_domain}"))
