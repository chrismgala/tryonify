# frozen_string_literal: true

class SlackMessageJob < ActiveJob::Base
  def perform(shop_id, message)
    shop = Shop.find(shop_id)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with ID '#{shop_id}'")
      return
    end

    service = SlackMessage.new(shop)
    service.send(message)
  end
end