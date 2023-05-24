# frozen_string_literal: true

desc "Create payments for overdue orders"
task create_payments: :environment do |_task, _args|
  puts "Creating payments..."

  Order.payment_due.joins(:shop).where(shop: { allow_automatic_payments: true }).find_each do |order|
    CreatePaymentJob.perform_later(order.id) unless order.ignored?
  end

  puts "done."
end
