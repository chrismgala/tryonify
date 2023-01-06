# frozen_string_literal: true

class ExtendTrial
  class InvalidRequest < StandardError; end

  EXTEND_TRIAL_QUERY = <<~QUERY
    mutation appSubscriptionTrialExtend($days: Int!, $id: ID!) {
      appSubscriptionTrialExtend(days: $days, id: $id) {
        appSubscription {
          id
          trialDays
        }
        userErrors {
          field
          message
        }
      }
    }
  QUERY

  def initialize
    session = ShopifyAPI::Context.active_session
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
  end

  def call
    service = FetchAppSubscription.new
    service.call

    raise "No subscription found" unless service.app

    variables = {
      days: 30,
      id: service.app.dig("activeSubscriptions", 0, "id"),
    }

    response = @client.query(query: EXTEND_TRIAL_QUERY, variables:)

    unless response.body["errors"].nil?
      raise ExtendTrial::InvalidRequest,
        response.body.dig("errors", 0, "message") and return
    end

    @order = response.body.dig("data", "order")
  end
end
