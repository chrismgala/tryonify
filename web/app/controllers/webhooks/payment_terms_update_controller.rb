# frozen_string_literal: true

module Webhooks
  class PaymentTermsUpdateController < ApplicationController
    include VerifySignature

    def receive
      PaymentTermsUpdateJob.perform_later(shop_domain: @shopify_event.dig("shop"), webhook: @shopify_event)
      head(:no_content)
    end
  end
end


