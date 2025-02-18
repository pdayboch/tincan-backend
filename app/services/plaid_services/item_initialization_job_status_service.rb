# frozen_string_literal: true

module PlaidServices
  class ItemInitializationJobStatusService
    SIDEKIQ_STATUS_MAPPING = {
      queued: 'pending',
      retrying: 'pending',
      working: 'pending',
      failed: 'failed',
      complete: 'completed'
    }.freeze

    def initialize(job_id)
      @job_id = job_id
    end

    def call
      normalize(Sidekiq::Status.status(@job_id))
    end

    private

    def normalize(sidekiq_status)
      SIDEKIQ_STATUS_MAPPING.fetch(sidekiq_status, 'failed')
    end
  end
end
