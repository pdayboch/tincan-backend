# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  class ApiInstitutionTest < ActiveSupport::TestCase
    setup do
      @plaid_client = mock('plaid_client')

      @error_response = {
        'error_type' => 'INVALID_INPUT',
        'error_code' => 'INVALID_INSTITUTION',
        'error_message' => 'invalid institution_id provided',
        'request_id' => '12345',
        'documentation_url' => 'https://plaid.com/docs'
      }.to_json

      @expected_log = 'Plaid Service Error: ' \
                      'type = INVALID_INPUT; ' \
                      'code = INVALID_INSTITUTION; ' \
                      'message = invalid institution_id provided; ' \
                      'request_id = 12345; ' \
                      'error_code_reason = ; ' \
                      'docs = https://plaid.com/docs;'

      Plaid::ApiClient.stubs(:new).returns(@plaid_client)
      Plaid::PlaidApi.stubs(:new).returns(@plaid_client)
    end

    test 'gets institution successfully' do
      mock_response = Plaid::InstitutionsGetByIdResponse.new(
        institution: Plaid::Institution.new(
          {
            country_codes: ['US'],
            name: 'test-bank'
          }
        )
      )

      @plaid_client.expects(:institutions_get_by_id)
                   .with(instance_of(Plaid::InstitutionsGetByIdRequest))
                   .returns(mock_response)

      response = PlaidServices::Api.institution_get('ins_1234')

      assert_equal mock_response, response
    end

    test 'handles get institution error' do
      api_error = Plaid::ApiError.new(response_body: @error_response)

      Rails.logger.expects(:error).with(@expected_log)
      @plaid_client.expects(:institutions_get_by_id).raises(api_error)

      assert_raises Plaid::ApiError do
        PlaidServices::Api.institution_get('bad_id')
      end
    end
  end
end
