# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  class ItemInitializationJobStatusesServiceTest < ActiveSupport::TestCase
    test 'returns pending for queued jobs' do
      Sidekiq::Status.stubs(:status).returns(:queued)
      result = ItemInitializationJobStatusesService.new('abc', '123').call
      assert_equal 'pending', result[:details_job_status]
      assert_equal 'pending', result[:sync_accounts_job_status]
    end

    test 'returns pending for retrying jobs' do
      Sidekiq::Status.stubs(:status).returns(:retrying)
      result = ItemInitializationJobStatusesService.new('abc', '123').call
      assert_equal 'pending', result[:details_job_status]
      assert_equal 'pending', result[:sync_accounts_job_status]
    end

    test 'returns pending for working jobs' do
      Sidekiq::Status.stubs(:status).returns(:working)
      result = ItemInitializationJobStatusesService.new('abc', '123').call
      assert_equal 'pending', result[:details_job_status]
      assert_equal 'pending', result[:sync_accounts_job_status]
    end

    test 'returns failed for failed jobs' do
      Sidekiq::Status.stubs(:status).returns(:failed)
      result = ItemInitializationJobStatusesService.new('abc', '123').call
      assert_equal 'failed', result[:details_job_status]
      assert_equal 'failed', result[:sync_accounts_job_status]
    end

    test 'returns completed for complete jobs' do
      Sidekiq::Status.stubs(:status).returns(:complete)
      result = ItemInitializationJobStatusesService.new('abc', '123').call
      assert_equal 'completed', result[:details_job_status]
      assert_equal 'completed', result[:sync_accounts_job_status]
    end

    test 'defaults to failed for unknown statuses' do
      Sidekiq::Status.stubs(:status).returns(:unknown)
      result = ItemInitializationJobStatusesService.new('abc', '123').call
      assert_equal 'failed', result[:details_job_status]
      assert_equal 'failed', result[:sync_accounts_job_status]
    end
  end
end
