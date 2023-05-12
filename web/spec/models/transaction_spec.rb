# frozen_string_literal: true

require "rails_helper"
require "support/stubs"

RSpec.describe(Transaction, type: :model) do
  before do
    @order = FactoryBot.create(:order)
    stubs = Stubs.new
    stubs.payment
    stubs.create_transaction
  end

  context "when an authorization transaction is created" do
    it "should cancel the order if the transaction is invalid" do
      @order.shop.with_shopify_session do
        invalid_transaction = FactoryBot.create(
          :transaction,
          kind: "authorization",
          error: "CARD_DECLINED",
          status: :failure,
          order: @order,
        )
        expect(OrderCancelJob).to(have_been_enqueued.with(invalid_transaction.order.id))
      end
    end

    it "should not cancel if the transaction is invalid and the order is fulfilled" do
      @order.shop.with_shopify_session do
        @order.update(fulfillment_status: "FULFILLED")
        @order.reload

        expect do
          FactoryBot.create(
            :transaction,
            kind: "authorization",
            error: "CARD_DECLINED",
            status: :failure,
            order: @order,
          )
        end.not_to(have_enqueued_job(OrderCancelJob))
      end
    end

    # it "should void the transaction if the shop has void_authorizations set to true" do
    #   @shop.update(void_authorizations: true)
    #   @shop.with_shopify_session do
    #     FactoryBot.create(:transaction, kind: "authorization", order: @order)
    #   end

    #   expect(Transaction.last.kind).to(eq("void"))
    # end
  end
end
