# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  class ApiTokenTest < ActiveSupport::TestCase
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

    test 'creates link token successfully' do
      user = users(:one)
      expected_token = 'test-link-token'
      link_token_response = mock('link_token_response')
      link_token_response.stubs(:link_token).returns(expected_token)

      @plaid_client.expects(:link_token_create)
                   .with(instance_of(Plaid::LinkTokenCreateRequest))
                   .returns(link_token_response)

      token = PlaidServices::Api.create_link_token(user)
      assert_equal expected_token, token
    end

    test 'handles link token creation error' do
      user = users(:one)
      api_error = Plaid::ApiError.new(response_body: @error_response)

      Rails.logger.expects(:error).with(@expected_log)
      @plaid_client.expects(:link_token_create).raises(api_error)

      assert_raises Plaid::ApiError do
        PlaidServices::Api.create_link_token(user)
      end
    end

    test 'exchanges public token successfully' do
      exchange_response = mock('exchange_response')
      @plaid_client.expects(:item_public_token_exchange)
                   .with(instance_of(Plaid::ItemPublicTokenExchangeRequest))
                   .returns(exchange_response)

      response = PlaidServices::Api.public_token_exchange('test-public-token')

      assert_equal exchange_response, response
    end

    test 'handles exchange public token error' do
      api_error = Plaid::ApiError.new(response_body: @error_response)

      Rails.logger.expects(:error).with(@expected_log)
      @plaid_client.expects(:item_public_token_exchange).raises(api_error)

      assert_raises Plaid::ApiError do
        PlaidServices::Api.public_token_exchange('test-public-token')
      end
    end
  end
end
