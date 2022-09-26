desc 'Fetch pending payment status'
task fetch_payment_status: :environment do |_task, _args|
  puts 'Fetching payment status...'

  Payment.where(status: 'PENDING').find_each do |payment|
    FetchPaymentStatusJob.perform_later(payment.id)
  end

  puts 'done.'
end
