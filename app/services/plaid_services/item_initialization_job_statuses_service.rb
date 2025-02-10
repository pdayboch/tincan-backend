# frozen_string_literal: true

module PlaidServices
  class ItemInitializationJobStatusesService
    SIDEKIQ_STATUS_MAPPING = {
      queued: 'pending',
      retrying: 'pending',
      working: 'pending',
      failed: 'failed',
      complete: 'completed'
    }.freeze

    def initialize(details_job_id, accounts_job_id)
      @details_job_id = details_job_id
      @accounts_job_id = accounts_job_id
    end

    def call
      {
        details_job_status: normalize(Sidekiq::Status.status(@details_job_id)),
        sync_accounts_job_status: normalize(Sidekiq::Status.status(@accounts_job_id))
      }
    end

    private

    def normalize(sidekiq_status)
      SIDEKIQ_STATUS_MAPPING.fetch(sidekiq_status, 'failed')
    end
  end
end
