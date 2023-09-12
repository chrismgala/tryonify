# frozen_string_literal: true

module Returns
  class FetchAll < ShopifyService
    FETCH_ALL_RETURNS_QUERY = <<~QUERY
      #{Returns::Fragments::RETURN_ITEM}
      query fetchReturns($id: ID!, $before: String) {
        order(id: $id) {
          ...on Order {
            id
            returns(first: 10, before: $before) {
              edges {
                node {
                  ...ReturnItem
                }
              }
            }
          }
        }
      }
    QUERY

    def initialize(order_id:, before: nil)
      super()
      @order_id = order_id
      @before = before
    end
  
    def call
      query = FETCH_ALL_RETURNS_QUERY
      variables = {
        id: @order_id,
        before: @before
      }
  
      response = client.query(query:, variables:)
  
      unless response.body["errors"].nil?
        raise response.body.dig("errors", 0, "message") and return
      end
  
      response
    rescue StandardError => err
      Rails.logger.error("[#{self.class} id=#{@order_id}]: #{err.message}")
      raise err
    end
  end
end