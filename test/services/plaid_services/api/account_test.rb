# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  class ApiAccountTest < ActiveSupport::TestCase
    setup do
      @plaid_client = mock('plaid_client')

      @error_response = {
        'error_type' => 'API_ERROR',
        'error_code' => 'INTERNAL_SERVER_ERROR',
        'error_message' => 'An internal server error occurred',
        'request_id' => '12345',
        'documentation_url' => 'https://plaid.com/docs'
      }.to_json

      @expected_log = 'Plaid Service Error: ' \
                      'type = API_ERROR; ' \
                      'code = INTERNAL_SERVER_ERROR; ' \
                      'message = An internal server error occurred; ' \
                      'request_id = 12345; ' \
                      'error_code_reason = ; ' \
                      'docs = https://plaid.com/docs;'

      Plaid::ApiClient.stubs(:new).returns(@plaid_client)
      Plaid::PlaidApi.stubs(:new).returns(@plaid_client)
    end

    test 'retrieves accounts successfully' do
      service = PlaidServices::Api.new('test-access-token')
      accounts_response = Plaid::AccountsGetResponse.new(
        accounts: Plaid::AccountBase.new(
          { account_id: 'abcd1234',
            name: 'test-account-name' }
        )
      )

      @plaid_client.expects(:accounts_get)
                   .with(instance_of(Plaid::AccountsGetRequest))
                   .returns(accounts_response)

      response = service.accounts

      assert_equal accounts_response, response
    end

    test 'handles get accounts error' do
      api_error = Plaid::ApiError.new(response_body: @error_response)

      Rails.logger.expects(:error).with(@expected_log)
      @plaid_client.expects(:accounts_get).raises(api_error)

      assert_raises Plaid::ApiError do
        PlaidServices::Api.new('test-access-token').accounts
      end
    end
  end
end
