# frozen_string_literal: true

desc "Fetch single pending payment status"
task :fetch_payment_status_single, [:id] => :environment do |_task, args|
  puts "Fetching payment status..."

  FetchPaymentStatusJob.perform_later(args[:id])

  puts "done."
end
