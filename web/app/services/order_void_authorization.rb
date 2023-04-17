# frozen_string_literal: true

class OrderVoidAuthorization < ApplicationService
  def initialize(order)
    super()
    @order = order
  end

  def call
    void if void_allowed?
  end

  private

  def void_allowed?
    @order.authorized? && !@order.voided?
  end

  def void
    authorized_transaction = @order.transactions.where(kind: :authorization).first
    TransactionCreate.call(
      order: @order,
      kind: "void",
      parent_id: authorized_transaction.shopify_id,
    )
  end
end
