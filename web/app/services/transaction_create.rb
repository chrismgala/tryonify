# frozen_string_literal: true

class TransactionCreate < ApplicationService
  def initialize(order:, kind:, parent_transaction_id: nil)
    super()
    @order = order
    @kind = kind
    @parent_transaction_id = parent_transaction_id
    @session = ShopifyAPI::Context.active_session
  end

  def call
    create_transaction
  end

  private

  def create_transaction
    shopify_transaction = ShopifyAPI::Transaction.new(session: @session)
    shopify_transaction.order_id = @order.shopify_id.split("/").last.to_i
    shopify_transaction.currency = @order.shop.currency_code
    shopify_transaction.kind = @kind

    if @parent_id
      parent_transaction = Transaction.find_by(shopify_id: @parent_transaction_id)
      shopify_transaction.parent_id = @parent_transaction_id
      shopify_transaction.amount = parent_transaction.amount
    end

    # Use the outstanding amount if no parent transaction is provided
    shopify_transaction.amount = @order.total_outstanding unless shopify_transaction.amount

    if shopify_transaction.save!
      Transaction.create!(
        shopify_id: shopify_transaction.id,
        order_id: @order.id,
        amount: shopify_transaction.amount.to_f,
        kind: @kind,
        parent_transaction: parent_transaction&.id,
        error: shopify_transaction.error_code,
      )
    end
  end
end
