# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Order, type: :model) do
  context "when as order is created" do
    let(:order) { FactoryBot.create(:order) }

    it "should pass validation" do
      expect(order.valid?).to(eq(true))
    end
  end

  context "when an order is created without a selling plan" do
    let(:order) { FactoryBot.build(:order, :without_selling_plan) }

    it "should fail validation" do
      expect(order.valid?).to(eq(false))
    end
  end
end
