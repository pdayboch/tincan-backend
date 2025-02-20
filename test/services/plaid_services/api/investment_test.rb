# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  class ApiInvestmentTest < ActiveSupport::TestCase
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

    test 'retrieves investments transactions successfully' do
      service = PlaidServices::Api.new('test-access-token')
      investments_transactions_response = Plaid::InvestmentsTransactionsGetResponse.new(
        investment_transactions: [
          Plaid::InvestmentTransaction.new(
            investment_transaction_id: 'investment-transaction-id',
            account_id: 'account-id',
            security_id: 'security-id',
            date: '2025-02-01',
            name: ''
          )
        ],
        total_investment_transactions: 200
      )

      @plaid_client.expects(:investments_transactions_get)
                   .with(instance_of(Plaid::InvestmentsTransactionsGetRequest))
                   .returns(investments_transactions_response)

      response = service.investments_transactions(
        start_date: '2024-01-01',
        end_date: '2025-01-31'
      )

      assert_equal investments_transactions_response, response
    end

    test 'handles get accounts error' do
      service = PlaidServices::Api.new('test-access-token')
      api_error = Plaid::ApiError.new(response_body: @error_response)

      Rails.logger.expects(:error).with(@expected_log)
      @plaid_client.expects(:investments_transactions_get)
                   .raises(api_error)

      assert_raises Plaid::ApiError do
        service.investments_transactions(
          start_date: '2024-01-01',
          end_date: '2025-01-31'
        )
      end
    end
  end
end
