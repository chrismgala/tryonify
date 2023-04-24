# frozen_string_literal: true

require "rails_helper"
require "support/stubs"

RSpec.describe(OrderCreate) do
  context "order is placed" do
    before do
      stub = Stubs.new
      stub.update_tags

      @shop = FactoryBot.create(:shop)
      selling_plan = FactoryBot.create(:selling_plan_group, shop: @shop).selling_plan
      @order_hash = FactoryBot.build(:order, shop: @shop).attributes
      @order_hash[:line_items_attributes] =
        FactoryBot.build_list(:line_item, 2, selling_plan:).map(&:attributes)
    end

    it "creates an order" do
      @shop.with_shopify_session do
        expect { OrderCreate.call(@order_hash.deep_symbolize_keys) }.to(change(Order, :count).by(1))
      end
    end
  end
end
