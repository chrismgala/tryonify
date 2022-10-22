# frozen_string_literal: true

class FetchAppSubscription
  class InvalidRequest < StandardError; end

  attr_accessor :error

  def initialize
    session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
    @error = nil
  end

  def call
    query = <<~QUERY
      query appSubscription {
        currentAppInstallation {
          activeSubscriptions {
            id, name, test
          }
        }
      }
    QUERY

    response = @client.query(query:)

    unless response.body['errors'].nil?
      raise FetchAppSubscription::InvalidRequest,
            response.body.dig('errors', 0, 'message') and return
    end

    response.body.dig('data', 'currentAppInstallation', 'activeSubscriptions')
  rescue StandardError => e
    Rails.logger.error("[FetchAppSubscription Failed]: #{e.message}")
    @error = e.message
  end
end
