# frozen_string_literal: true

require "rails_helper"
require "support/stubs"

RSpec.describe(OrderCreate) do
  before do
    stub = Stubs.new
    stub.update_tags

    @shop = FactoryBot.create(:shop)
    selling_plan = FactoryBot.create(:selling_plan_group, shop: @shop).selling_plan
    @order_hash = FactoryBot.build(:order, shop: @shop).attributes
    @order_hash[:line_items_attributes] =
      FactoryBot.build_list(:line_item, 2, selling_plan:).map(&:attributes)
    @order_hash.deep_symbolize_keys!
  end

  context "order is placed" do
    it "creates an order" do
      @shop.with_shopify_session do
        expect { OrderCreate.call(@order_hash) }.to(change(Order, :count).by(1))
      end
    end
  end

  context "after order is placed" do
    context "the shop has authorize_transactions set to true" do
      before do
        @shop.update(authorize_transactions: true)
        @shop.with_shopify_session do
          OrderCreate.call(@order_hash)
        end
      end

      it "enqueues a payment authorization job " do
        expect(OrderAuthorizeJob).to(have_been_enqueued.with(Order.last.id))
      end
    end

    context "the shop has authorize_transactions set to false" do
      before do
        @shop.update(authorize_transactions: false)
      end

      it "does not enqueue a payment authorization job " do
        @shop.with_shopify_session do
          expect { OrderCreate.call(@order_hash) }.not_to(have_enqueued_job(OrderAuthorizeJob))
        end
      end
    end
  end
end
