# frozen_string_literal: true

module Api
  module V1
    module Webhooks
      class PaymentTermsUpdateController < BaseWebhookController
        include VerifySignature

        def receive
          PaymentTermsUpdateJob.perform_later(shop_domain: @shop_domain, webhook: @shopify_event)
          head(:no_content)
        end
      end
    end
  end
end


