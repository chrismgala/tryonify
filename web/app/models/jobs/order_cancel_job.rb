module Jobs
  class OrderCancelJob < Job
    ORDER_STATUS_QUERY = <<~QUERY
      query fetchOrderCancelledStatus($id: ID!) {
        order(id: $id) {
          ... on Order {
            cancelledAt
          }
        }
      }
    QUERY

    def status
      shop.with_shopify_session do
        response = Shopify::Jobs::Fetch.call(shopify_id: shopify_id, query: ORDER_STATUS_QUERY)
        if response.body.dig('data', 'job', 'done')
          done = response.body.dig('data', 'job', 'done')
          update!(done: done)
        end
      end
    end
  end
end
