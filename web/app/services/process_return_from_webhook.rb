# frozen_string_literal: true

class ProcessReturnFromWebhook
  def initialize(body)
    @body = body
  end

  def call
    return unless has_return

    @body.dig('refunds').each do |refund|
      refund.dig('refund_line_items').each do |refund_line_item|
        existing_return = Return.where(shopify_id: "gid://shopify/LineItem/#{refund_line_item.dig('line_item_id')}",
                                       active: true).first

        existing_return.update(active: false) if existing_return
      end
    end
  rescue StandardError => e
    Rails.logger.error("[ProcessReturnFromWebhook Failed]: Order ID - #{@body.dig('id')} #{e.message}")
  end

  def has_return
    @body.dig('refunds').length > 0
  end
end
