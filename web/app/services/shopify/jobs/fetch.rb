# frozen_string_literal: true

module Shopify
  class Jobs::Fetch < Shopify::Base
    attr_accessor :error

    FETCH_JOB_QUERY = <<~QUERY
      query fetchJob($id: ID!) {
        job(id: $id) {
          id
          done
        }
      }
    QUERY

    def initialize(shopify_id:, query:)
      super()

      @shopify_id = shopify_id
      @query = query
      @error = nil
    end

    def call
      fetch_job
    rescue StandardError => e
      Rails.logger.error("[#{self.class} Failed]: #{e.message}]")
      raise e
    end

    private

    def fetch_job
      response = client.query(query: FETCH_JOB_QUERY, variables: {
        id: @shopify_id
      })

      unless response.body['errors'].blank?
        @error = response.body['errors'].map { |error| error['message'] }.join(', ')
        raise StandardError.new, @error
      end

      response
    end
  end
end
