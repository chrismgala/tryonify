class ShopUpdateJob < ActiveJob::Base
  discard_on ActiveRecord::RecordNotFound

  def perform(shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    shop.update({
                  email: webhook.dig('email')
                })
  end
end
