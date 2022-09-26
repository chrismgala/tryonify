desc 'Create payments for overdue orders'
task create_payments: :environment do |_task, _args|
  puts 'Creating payments...'

  Order.payment_due.find_each do |order|
    CreatePaymentJob.perform_later(order.id)
  end

  puts 'done.'
end
