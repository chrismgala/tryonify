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

  context "latest_authorization" do
    let(:order) { FactoryBot.create(:order) }

    it "returns the most recent authorization" do
      FactoryBot.create_list(:transaction, 4, status: :success, kind: :authorization,
        order: order) do |transaction, index|
        transaction.update(authorization_expires_at: index.days.from_now)
      end
      transactions = order.transactions.successful_authorizations.order(authorization_expires_at: :desc)
      expect(order.latest_authorization.authorization_expires_at).to(be > transactions[1].authorization_expires_at)
    end
  end
end
