# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Order, type: :model) do
  after do
    Sidekiq::Queue.all.each(&:clear)
  end

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

  context "when and order has a return" do
    it "should update the due date" do
      order = FactoryBot.create(:order, :with_return)
      expect(OrderUpdateDueDateJob).to(have_been_enqueued.with(order: order, due_date: order.calculated_due_date))
    end
  end

  describe "#calculated_due_date" do
    context "when the order has a trial return" do
      it "should return the due date if return period is within trial period" do
        order = FactoryBot.create(:order, :with_return, due_date: 14.days.from_now)
        expect(order.calculated_due_date).to(eq(order.due_date))
      end

      it "should return the max due date if the return period is beyond that max due date" do
        order = FactoryBot.create(:order, :with_return, shopify_created_at: 16.days.ago, due_date: 2.days.from_now)
        expect(order.calculated_due_date).to(eq(order.max_due_date))
      end
    end
  end
end
