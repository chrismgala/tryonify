# frozen_string_literal: true

# Fetch the current app ID, this is used for app specific
# metafields.
class Shopify::App::FetchCurrent < Shopify::Base
  FETCH_CURRENT_APP_QUERY = <<~QUERY
    query app {
      app {
        id
      }
    }
  QUERY

  def call
    response = client.query(query: FETCH_CURRENT_APP_QUERY)

    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  end
end
