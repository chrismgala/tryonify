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
      @order.shop.authorize_transactions = true
      @order.shop.save!
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

    it "should not cancel if the transaction is a reauthorization" do
      FactoryBot.create(:transaction, status: :success, order: @order)
      FactoryBot.create(
        :transaction,
        kind: "authorization",
        error: "CARD_DECLINED",
        status: :failure,
        order: @order,
      )
      expect(OrderCancelJob).to_not(have_been_enqueued.with(@order.id))
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
  end

  context "when a prepaid card is used" do
    it "should cancel if pre-paid cards are not allowed" do
      @order.shop.cancel_prepaid_cards = true
      @order.shop.save!
      transaction = FactoryBot.create(:transaction, :with_prepaid_card, order: @order)
      expect(OrderCancelJob).to(have_been_enqueued.with(transaction.order.id))
    end

    it "should do nothing if pre-paid cards are allowed" do
      @order.shop.cancel_prepaid_cards = false
      @order.shop.save!
      transaction = FactoryBot.create(:transaction, :with_prepaid_card, order: @order)
      expect(OrderCancelJob).to_not(have_been_enqueued.with(transaction.order.id))
    end
  end
end
