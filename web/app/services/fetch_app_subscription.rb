# frozen_string_literal: true

class FetchAppSubscription
  class InvalidRequest < StandardError; end

  attr_accessor :error

  def initialize
    session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
    @error = nil
  end

  def call
    begin
      query = <<~QUERY
        query appSubscription {
          currentAppInstallation {
            activeSubscriptions {
              name, test
            }
          }
        }
      QUERY

      response = @client.query(query: query)

      raise FetchAppSubscription::InvalidRequest, response.body.dig('errors', 0, 'message') and return unless response.body['errors'].nil?

      return response.body.dig('data', 'currentAppInstallation', 'activeSubscriptions')
    rescue StandardError => e
      Rails.logger.error("[FetchAppSubscription Failed]: #{e.message}")
      @error = e.message
    end
  end
end