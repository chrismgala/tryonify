# frozen_string_literal: true

class CreateMetafieldJob < ActiveJob::Base
  def perform(shop_id, attributes)
    shop = Shop.find(shop_id)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with id #{shop_id}")
      return
    end

    shop.with_shopify_session do
      service = CreateMetafield.new({
        key: attributes[:key],
        namespace: attributes[:namespace],
        type: attributes[:type],
        value: attributes[:value],
      })
      service.call
    end
  end
end
