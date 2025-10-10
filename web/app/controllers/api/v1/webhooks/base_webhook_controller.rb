# frozen_string_literal: true

module Api
  module V1
    module Webhooks
      class BaseWebhookController < ApplicationController
        # Skip CSRF verification for webhooks from external services
        skip_before_action :verify_authenticity_token
      end
    end
  end
end