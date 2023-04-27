# frozen_string_literal: true

require "rails_helper"
require "support/stubs"

RSpec.describe(FetchPaymentStatus) do
  before do
    @stub = Stubs.new
    @shop = FactoryBot.create(:shop)
    @order = FactoryBot.create(:order, shop: @shop)
    @payment = FactoryBot.create(:payment, order: @order, status: "PENDING")
  end

  context "when a payment is captured" do
    it "should update the status to PAID" do
      @shop.with_shopify_session do
        @stub.payment_status_paid
        service = FetchPaymentStatus.new(@payment.id)
        service.call
        @payment.reload

        expect(@payment.status).to(eq("PAID"))
      end
    end
  end

  # context "when a payment status is fetched" do
  #   before do
  #     @shop.with_shopify_session do
  #       @payment = PaymentCreate.call(@payment_hash)
  #     end
  #   end

  #   context "when the payment is authorized" do
  #     it "should enqueue a payment authorization job" do
  #       @shop.with_shopify_session do
  #         FetchPaymentStatusJob.perform_now(@payment.id)
  #       end

  #       expect(FetchPaymentStatusJob).to(have_been_enqueued.with(@payment.id))
  #     end
  #   end

  #   context "when the payment is not authorized" do
  #     it "should not enqueue a payment authorization job" do
  #       @shop.with_shopify_session do
  #         @payment.update(status: "ERROR")
  #         FetchPaymentStatusJob.perform_now(@payment.id)
  #       end

  #       expect(FetchPaymentStatusJob).not_to(have_been_enqueued.with(@payment.id))
  #     end
  #   end
  # end
end
