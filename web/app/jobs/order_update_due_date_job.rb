# frozen_string_literal: true

class OrderUpdateDueDateJob < ActiveJob::Base
  discard_on ActiveRecord::RecordNotFound

  def perform(order:, due_date:)
    if order.nil?
      logger.error("#{self.class} failed: cannot find order with ID '#{order}'")
      return
    end

    return unless order.pending?
    
    order.shop.with_shopify_session do
      response = Shopify::PaymentTerms::Update.call(
        payment_terms_id: order.payment_terms_id,
        due_date: due_date
      )

      updated_due_date = response.body.dig('data', 'paymentTermsUpdate', 'paymentTerms', 'paymentSchedules', 'edges', 0, 'node', 'dueAt')
      order.update(due_date: updated_due_date) if updated_due_date.present?
    end
  end
end