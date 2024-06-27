# frozen_string_literal: true

class FetchJobStatusJob < ApplicationJob
  queue_as :default

  def perform(job)
    job.status
  end
end
