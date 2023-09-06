# frozen_string_literal: true

class UpdateReturnOrderNoteJob < ActiveJob::Base
  def perform(shop_id, return_id)
    shop = Shop.find(shop_id)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with ID '#{shop_id}'")
      return
    end

    shop.with_shopify_session do
      service = UpdateReturnOrderNote.new(shop_id, return_id)
      service.call
    end
  end
end