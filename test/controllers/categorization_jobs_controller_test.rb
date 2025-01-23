# frozen_string_literal: true

require 'test_helper'

class CategorizationJobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Ensure jobs are not performed but only enqueued
    Sidekiq::Testing.fake!
  end

  teardown do
    # Clear all Sidekiq queues after each test
    Sidekiq::Worker.clear_all
  end

  test 'should create job and return sucess' do
    assert_difference -> { CategorizeTransactionsJob.jobs.size }, 1 do
      post categorization_jobs_url
    end

    assert_response :accepted
    assert_equal({ 'accepted' => 'success' }, response.parsed_body)
  end
end
