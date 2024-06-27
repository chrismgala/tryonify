module Shopify
  class Webhooks::FetchAll < Shopify::Base
    attr_accessor :error

    FETCH_WEBHOOKS_QUERY = <<~QUERY
      query {
        webhookSubscriptions(first: 20) {
          edges {
            node {
              id
              topic
              endpoint {
                __typename
                ... on WebhookHttpEndpoint {
                  callbackUrl
                }
              }
            }
          }
        }
      }
    QUERY

    def initialize
      super()
      @error = nil
    end

    def call
      fetch_webhooks
    rescue StandardError => e
      Rails.logger.error("[#{self.class} Failed]: #{e.message}]")
      raise e
    end

    private

    def fetch_webhooks
      response = client.query(query: FETCH_WEBHOOKS_QUERY)

      unless response.body['errors'].blank?
        @error = response.body['errors'].map { |error| error['message'] }.join(', ')
        raise StandardError.new, @error
      end

      response
    end
  end
end
