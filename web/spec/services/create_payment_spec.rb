# frozen_string_literal: true

require "rails_helper"
require "support/stubs"

RSpec.describe(CreatePayment) do
  context "order is due" do
    let(:order) { FactoryBot.create(:order, due_date: 1.day.ago) }

    before do
      stub = Stubs.new
      stub.order(order.shopify_id)
    end

    it "creates a payment" do
      order.shop.with_shopify_session do
        service = CreatePayment.new(order.id)
        service.call
      end

      expect(Payment.where(order_id: order.id)).to(exist)
    end
  end

  context "order is due with a pending return" do
    let!(:order) { FactoryBot.create(:order, :with_return, due_date: 1.day.ago) }

    before do
      stub = Stubs.new
      stub.order(order.shopify_id)
    end

    it "does not create a payment" do
      order.shop.with_shopify_session do
        service = CreatePayment.new(order.id)
        service.call
      end

      expect(Payment.where(order_id: order.id)).to_not(exist)
    end

    it "creates a payment if return period has lapsed" do
      order.due_date = 100.days.ago
      order.save!

      return_item = order.returns.first
      return_item.created_at = 90.days.ago
      return_item.save!

      order.shop.with_shopify_session do
        service = CreatePayment.new(order.id)
        service.call
      end

      expect(Payment.where(order_id: order.id)).to(exist)
    end
  end

  context "order is due with a processed return" do
    let(:order) { FactoryBot.create(:order, due_date: 1.day.ago) }
    let(:return) { FactoryBot.create(:return, shop: order.shop, order:, active: false) }

    before do
      stub = Stubs.new
      stub.order(order.shopify_id)
    end

    it "creates a payment" do
      order.shop.with_shopify_session do
        service = CreatePayment.new(order.id)
        service.call
      end

      expect(Payment.where(order_id: order.id)).to(exist)
    end
  end

  context "order is not due" do
    let(:order) { FactoryBot.create(:order, due_date: 1.day.from_now) }

    before do
      stub = Stubs.new
      stub.order(order.shopify_id)
    end

    it "does not create a payment" do
      order.shop.with_shopify_session do
        service = CreatePayment.new(order.id)
        service.call
      end

      expect(Payment.where(order_id: order.id)).to_not(exist)
    end
  end
end
