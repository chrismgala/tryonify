# frozen_string_literal: true

class FetchAppSubscription
  class InvalidRequest < StandardError; end

  attr_accessor :app, :error

  def initialize
    session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
    @app = nil
    @error = nil
  end

  def call
    query = <<~QUERY
      query appSubscription {
        currentAppInstallation {
          id
          activeSubscriptions {
            id, name, test, trialDays
          }
        }
      }
    QUERY

    response = @client.query(query:)

    unless response.body["errors"].nil?
      raise FetchAppSubscription::InvalidRequest,
        response.body.dig("errors", 0, "message") and return
    end

    @app = response.body.dig("data", "currentAppInstallation")
  rescue StandardError => e
    Rails.logger.error("[FetchAppSubscription Failed]: #{e.message}")
    @error = e.message
  end
end
