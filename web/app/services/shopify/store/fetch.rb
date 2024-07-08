module Shopify
  class Store::Fetch < Shopify::Base
    attr_accessor :error

    FETCH_STORE_QUERY = <<~QUERY
      query {
        shop {
          id
          url
          email
          currencyCode
          plan {
            displayName
            partnerDevelopment
            shopifyPlus
          }
        }
      }
    QUERY

    def initialize
      super()
      @error = nil
    end

    def call
      fetch_store
    rescue StandardError => e
      Rails.logger.error("[#{self.class} Failed]: #{e.message}]")
      raise e
    end

    private

    def fetch_store
      response = client.query(query: FETCH_STORE_QUERY)

      unless response.body['errors'].blank?
        @error = response.body['errors'].map { |error| error['message'] }.join(', ')
        raise StandardError.new, @error
      end

      response
    end
  end
end
