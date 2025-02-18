# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  class ItemInitializationJobStatusServiceTest < ActiveSupport::TestCase
    test 'returns pending for queued jobs' do
      Sidekiq::Status.stubs(:status).returns(:queued)
      result = ItemInitializationJobStatusService.new('123').call
      assert_equal 'pending', result
    end

    test 'returns pending for retrying jobs' do
      Sidekiq::Status.stubs(:status).returns(:retrying)
      result = ItemInitializationJobStatusService.new('123').call
      assert_equal 'pending', result
    end

    test 'returns pending for working jobs' do
      Sidekiq::Status.stubs(:status).returns(:working)
      result = ItemInitializationJobStatusService.new('123').call
      assert_equal 'pending', result
    end

    test 'returns failed for failed jobs' do
      Sidekiq::Status.stubs(:status).returns(:failed)
      result = ItemInitializationJobStatusService.new('123').call
      assert_equal 'failed', result
    end

    test 'returns completed for complete jobs' do
      Sidekiq::Status.stubs(:status).returns(:complete)
      result = ItemInitializationJobStatusService.new('123').call
      assert_equal 'completed', result
    end

    test 'defaults to failed for unknown statuses' do
      Sidekiq::Status.stubs(:status).returns(:unknown)
      result = ItemInitializationJobStatusService.new('123').call
      assert_equal 'failed', result
    end
  end
end
