# frozen_string_literal: true

module VerifySignature
  extend ActiveSupport::Concern

  included do
    before_action :verify_signature
  end
end

def verify_signature
  hookdeck_webhook_secret = ENV['HOOKDECK_WEBHOOK_SECRET']
  return false if hookdeck_webhook_secret.blank?

  # Get raw payload for signature verification
  payload = request.raw_post

  # Get signature headers
  signature = request.env['HTTP_X_HOOKDECK_SIGNATURE']
  signature2 = request.env['HTTP_X_HOOKDECK_SIGNATURE_2']
  
  hash = Base64.encode64(
    OpenSSL::HMAC.digest('sha256', hookdeck_webhook_secret, payload)
  ).strip

  # Compare the created hash with the value of the x-hookdeck-signature and x-hookdeck-signature-2 headers
  if hash == signature || (signature2 && hash == signature2)
    puts "Webhook is originating from Hookdeck"
    
    # Parse webhook data
    @shopify_event = JSON.parse(payload)
    @shop_domain = request.env['HTTP_X_SHOPIFY_SHOP_DOMAIN']
    event_type = request.env['HTTP_X_SHOPIFY_TOPIC']
    { success: true }.to_json
  else
    puts "Signature is invalid, rejected"
    halt 403, { error: 'Invalid signature' }.to_json
  end
end