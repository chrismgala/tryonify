# frozen_string_literal: true

require "rails_helper"
require "support/stubs"

RSpec.describe(ReauthorizeOrders) do
  context "a pending order" do
    context "has an authorization that is expiring" do
      let(:order) { FactoryBot.create(:order, :with_expiring_authorization) }
      it "should reauthorize the order" do
        ReauthorizeOrders.call(order.shop)
        expect(OrderAuthorizeJob).to(have_been_enqueued.with(order.id))
      end
    end

    context "has no authorization that is expiring" do
      let(:order) { FactoryBot.create(:order, :with_valid_authorizations) }
      it "should not reauthorize the order" do
        ReauthorizeOrders.call(order.shop)
        expect(OrderAuthorizeJob).not_to(have_been_enqueued.with(order.id))
      end
    end

    context "failed to reauthorize" do
      it "should not cancel" do
        order = FactoryBot.create(:order, :with_expiring_authorization)
        FactoryBot.create(:transaction, :failure, order: order)
        ReauthorizeOrders.call(order.shop)
        expect(OrderCancelJob).not_to(have_been_enqueued.with(order.id))
      end
    end
  end

  context "a PayPal pending order" do
    context "has an authorization that is expiring" do
      let(:order) { FactoryBot.create(:order, :with_expiring_paypal_authorization) }
      it "should reauthorize the order" do
        ReauthorizeOrders.call(order.shop)
        expect(OrderAuthorizeJob).to(have_been_enqueued.with(order.id))
      end
    end
  end
end
