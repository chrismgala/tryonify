# frozen_string_literal: true

class BulkOperationsFinishJob < ApplicationJob
  extend ShopifyAPI::Webhooks::Handler

  class << self
    def handle(topic:, shop:, body:)
      perform_later(topic:, shop_domain: shop, webhook: body)
    end
  end

  def perform(topic:, shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    bulk_operation = BulkOperation.find_by(shopify_id: webhook['admin_graphql_api_id'])

    if bulk_operation
      bulk_operation.status = webhook['status']
      bulk_operation.error_code = webhook['error_code']
      bulk_operation.completed_at = webhook['completed_at']

      shop.with_shopify_session do
        response = Shopify::BulkOperation::Fetch.call(bulk_operation.shopify_id)

        bulk_operation.url = response.body.dig('data', 'node', 'url')
        bulk_operation.save

        UpdateFromBulkOperation.call(bulk_operation)
      end
    end
  end
end
