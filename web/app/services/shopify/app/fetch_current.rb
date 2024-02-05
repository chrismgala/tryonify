# frozen_string_literal: true

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
    puts response.inspect
    unless response.body["errors"].nil?
      raise response.body.dig("errors", 0, "message") and return
    end

    response
  end
end
