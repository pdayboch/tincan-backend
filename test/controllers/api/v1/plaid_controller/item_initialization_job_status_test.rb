# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class PlaidControllerItemInitializationJobStatusTest < ActionDispatch::IntegrationTest
      test 'calls item initialization job status service and returns result' do
        mock_service = mock('job-status-service')

        PlaidServices::ItemInitializationJobStatusService.expects(:new)
                                                         .with('123')
                                                         .returns(mock_service)

        mock_service.expects(:call)
                    .returns({
                               sync_accounts_job_status: 'completed'
                             })

        get api_v1_plaid_item_initialization_job_status_url, params: {
          jobId: '123'
        }

        expected_resp = {
          'status' => 'completed'
        }

        assert expected_resp, response.parsed_body
      end

      test 'returns bad request without job_id' do
        get api_v1_plaid_item_initialization_job_status_url

        error_resp = { 'errors' => [
          { 'field' => 'jobId', 'message' => 'is required' }
        ] }
        assert_equal error_resp, response.parsed_body
        assert_response :bad_request
      end
    end
  end
end
