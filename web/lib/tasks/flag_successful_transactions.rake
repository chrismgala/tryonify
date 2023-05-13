# frozen_string_literal: true

desc "Flag successful transactions"
task :flag_successful_transactions, [:shop_domain] => :environment do |_task, args|
  puts "Flagging successful transactions..."

  shop = Shop.find_by!(shopify_domain: args[:shop_domain])

  if shop.nil?
    puts "Shop #{args[:shop_domain]} not found."
    return
  end

  shop.with_shopify_session do
    shop.orders.pending.each do |order|
      response = OrderTransactionFetch.call(order)
      response.body.dig("data", "order", "transactions")&.each do |transaction|
        existing_transaction = order.transactions.find_by(shopify_id: transaction["id"])
        if existing_transaction
          existing_transaction.update!(
            status: transaction["status"].downcase,
            gateway: transaction["gateway"],
            authorization_expires_at: (transaction["kind"].downcase == "authorization") && (transaction["status"].downcase == "success") ? get_authorization_expiration_date(transaction) : nil,
          )
        end
      end
      sleep 1
    end
  end

  puts "done."
end

def get_authorization_expiration_date(transaction)
  if transaction["kind"].downcase == "authorization" && transaction["authorizationExpiresAt"].blank?
    if (transaction["createdAt"].to_date + 3.days) < 3.days.from_now
      return transaction["createdAt"].to_date + 3.days
    else
      return 3.days.from_now
    end
  end

  transaction["authorizationExpiresAt"]
end
