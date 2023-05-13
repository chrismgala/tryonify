# frozen_string_literal: true

class OrderTransactionsUpdate < ApplicationService
  attr_accessor :error

  def initialize(order)
    super()
    @order = order
    @transactions = nil
  end

  def call
    @order.shop.with_shopify_session do
      @transactions = OrderTransactionFetch.call(@order)
      save_order_transactions
    end
  end

  private

  def save_order_transactions
    @transactions.body.dig("data", "order", "transactions")&.each do |transaction|
      parent_transaction = @order.transactions.find_by(shopify_id: transaction.dig("parentTransaction", "id"))
      found_transaction = @order.transactions.find_or_create_by!(shopify_id: transaction["id"]) do |t|
        t.payment_id = transaction["paymentId"]
        t.receipt = transaction["receiptJson"]
        t.kind = transaction["kind"].downcase
        t.amount = transaction.dig("amountSet", "shopMoney", "amount")
        t.status = transaction["status"].downcase
        t.gateway = transaction["gateway"]
        t.authorization_expires_at = get_authorization_expiration_date(transaction)
        t.error = transaction["errorCode"]
      end

      # Update parent transaction reference
      if parent_transaction
        found_transaction.update!(parent_transaction: parent_transaction)
        parent_transaction.update!(voided: true)
      end
    end
  end

  def get_authorization_expiration_date(transaction)
    if transaction["kind"].downcase == "authorization" && transaction["authorizationExpiresAt"].blank? && transaction["status"].downcase == "success"
      if (transaction["createdAt"].to_date + 3.days) < 3.days.from_now
        return transaction["createdAt"].to_date + 3.days
      else
        return 3.days.from_now
      end
    end

    transaction["authorizationExpiresAt"]
  end
end
