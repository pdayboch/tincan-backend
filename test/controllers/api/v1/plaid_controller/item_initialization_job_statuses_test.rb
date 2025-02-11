# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class PlaidControllerItemInitializationJobStatusesTest < ActionDispatch::IntegrationTest
      test 'calls item initialization job statuses service and returns result' do
        mock_service = mock('job-status-service')

        PlaidServices::ItemInitializationJobStatusesService.expects(:new)
                                                           .with('abc', '123')
                                                           .returns(mock_service)

        mock_service.expects(:call)
                    .returns({
                               details_job_status: 'pending',
                               sync_accounts_job_status: 'completed'
                             })

        get api_v1_plaid_item_initialization_job_statuses_url, params: {
          detailsJobId: 'abc',
          syncAccountsJobId: '123'
        }

        expected_resp = {
          'detailsJobStatus' => 'pending',
          'syncAccountsJobStatus' => 'completed'
        }

        assert expected_resp, response.parsed_body
      end

      test 'returns bad request without details_job_id' do
        get api_v1_plaid_item_initialization_job_statuses_url, params: {
          syncAccountsJobId: 'abc'
        }

        error_resp = { 'errors' => [
          { 'field' => 'detailsJobId', 'message' => 'is required' }
        ] }
        assert_equal error_resp, response.parsed_body
        assert_response :bad_request
      end

      test 'returns bad request without sync_accounts_job_id' do
        get api_v1_plaid_item_initialization_job_statuses_url, params: {
          detailsJobId: 'abc'
        }

        error_resp = { 'errors' => [
          { 'field' => 'syncAccountsJobId', 'message' => 'is required' }
        ] }
        assert_equal error_resp, response.parsed_body
        assert_response :bad_request
      end
    end
  end
end
