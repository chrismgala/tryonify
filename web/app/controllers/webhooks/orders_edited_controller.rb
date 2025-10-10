# frozen_string_literal: true

module Webhooks
  class OrdersEditedController < ApplicationController
    include VerifySignature

    def receive
      OrdersEditedJob.perform_later(shop_domain: @shopify_event.dig("shop"), webhook: @shopify_event)
      head(:no_content)
    end
  end
end


