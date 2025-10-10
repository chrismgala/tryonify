# frozen_string_literal: true

module Api
  module V1
    module Webhooks
      class ReturnsApproveController < ApplicationController
      include VerifySignature

      def receive
        ReturnsApproveJob.perform_later(shop_domain: @shopify_event.dig("shop"), webhook: @shopify_event)
        head(:no_content)
      end
    end
  end
end


