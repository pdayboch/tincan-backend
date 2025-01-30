# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  class ApiTransactionTest < ActiveSupport::TestCase
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

    test 'retrieves transactions single page successfully' do
      service = PlaidServices::Api.new(@access_token)
      response = mock('response')
      response.stubs(
        next_cursor: 'next-cursor',
        added: ['transaction1'],
        modified: ['modified1'],
        removed: ['removed1'],
        has_more: false
      )

      expected_result = {
        next_cursor: 'next-cursor',
        added: %w[transaction1],
        modified: ['modified1'],
        removed: ['removed1']
      }

      @plaid_client.expects(:transactions_sync)
                   .with { |req| req.cursor == '' && req.access_token == @access_token }
                   .returns(response)

      result = service.transactions_sync

      assert_equal expected_result, result
    end

    test 'retrieves transactions multiple pages successfully' do
      service = PlaidServices::Api.new(@access_token)
      first_response = mock('first_response')
      first_response.stubs(
        next_cursor: 'next-cursor',
        added: ['transactions1'],
        modified: ['modified1'],
        removed: [],
        has_more: true
      )

      second_response = mock('second_response')
      second_response.stubs(
        next_cursor: 'next-cursor-2',
        added: ['transactions2'],
        modified: [],
        removed: ['removed2'],
        has_more: false
      )

      expected_result = {
        next_cursor: 'next-cursor-2',
        added: %w[transactions1 transactions2],
        modified: ['modified1'],
        removed: ['removed2']
      }

      @plaid_client.expects(:transactions_sync)
                   .with { |req| req.cursor == '' && req.access_token == @access_token }
                   .returns(first_response)

      @plaid_client.expects(:transactions_sync)
                   .with { |req| req.cursor == 'next-cursor' && req.access_token == @access_token }
                   .returns(second_response)

      result = service.transactions_sync

      assert_equal expected_result, result
    end

    test 'retrieves transactions with initial cursor' do
      service = PlaidServices::Api.new(@access_token)
      response = mock('response')
      response.stubs(
        next_cursor: 'next-cursor-2',
        added: ['transaction1'],
        modified: ['modified1'],
        removed: ['removed1'],
        has_more: false
      )

      expected_result = {
        next_cursor: 'next-cursor-2',
        added: %w[transaction1],
        modified: ['modified1'],
        removed: ['removed1']
      }

      @plaid_client.expects(:transactions_sync)
                   .with { |req| req.cursor == 'next-cursor' && req.access_token == @access_token }
                   .returns(response)

      result = service.transactions_sync('next-cursor')

      assert_equal expected_result, result
    end

    test 'restarts transaction sync with mutation error' do
      service = PlaidServices::Api.new(@access_token)
      first_response = mock('first_response')
      first_response.stubs(
        next_cursor: 'next-cursor-2',
        added: ['transactions1'],
        modified: ['modified1'],
        removed: [],
        has_more: true
      )

      mutation_error_response = {
        'error_type' => 'TRANSACTIONS_ERROR',
        'error_code' => Api::MUTATION_ERROR,
        'error_message' => 'Underlying transaction data changed since last page was fetched.',
        'request_id' => '12345',
        'documentation_url' => 'https://plaid.com/docs'
      }.to_json

      api_mutation_error = Plaid::ApiError.new(response_body: mutation_error_response)

      second_response = mock('second_response')
      second_response.stubs(
        next_cursor: 'next-cursor-3',
        added: ['transactions2'],
        modified: [],
        removed: ['removed2'],
        has_more: false
      )

      expected_result = {
        next_cursor: 'next-cursor-3',
        added: %w[transactions1 transactions2],
        modified: ['modified1'],
        removed: ['removed2']
      }

      sync_sequence = sequence('sync_calls')

      @plaid_client.expects(:transactions_sync)
                   .with { |req| req.cursor == 'next-cursor' && req.access_token == @access_token }
                   .returns(first_response)
                   .in_sequence(sync_sequence)

      @plaid_client.expects(:transactions_sync)
                   .with { |req| req.cursor == 'next-cursor-2' && req.access_token == @access_token }
                   .raises(api_mutation_error)
                   .in_sequence(sync_sequence)

      @plaid_client.expects(:transactions_sync)
                   .with { |req| req.cursor == 'next-cursor' && req.access_token == @access_token }
                   .returns(first_response)
                   .in_sequence(sync_sequence)

      @plaid_client.expects(:transactions_sync)
                   .with { |req| req.cursor == 'next-cursor-2' && req.access_token == @access_token }
                   .returns(second_response)
                   .in_sequence(sync_sequence)

      result = service.transactions_sync('next-cursor')

      assert_equal expected_result, result
    end

    test 'transaction sync raises error after max retries' do
      service = PlaidServices::Api.new(@access_token)

      first_response = mock('first_response')
      first_response.stubs(
        next_cursor: 'next-cursor-2',
        added: ['transactions1'],
        modified: ['modified1'],
        removed: [],
        has_more: true
      )

      mutation_error_response = {
        'error_type' => 'TRANSACTIONS_ERROR',
        'error_code' => Api::MUTATION_ERROR,
        'error_message' => 'Underlying transaction data changed since last page was fetched.',
        'request_id' => '12345',
        'documentation_url' => 'https://plaid.com/docs'
      }.to_json

      api_mutation_error = Plaid::ApiError.new(response_body: mutation_error_response)

      sync_sequence = sequence('sync_calls')

      @plaid_client.expects(:transactions_sync)
                   .with { |req| req.cursor == 'next-cursor' && req.access_token == @access_token }
                   .returns(first_response)
                   .in_sequence(sync_sequence)

      @plaid_client.expects(:transactions_sync)
                   .with { |req| req.cursor == 'next-cursor-2' && req.access_token == @access_token }
                   .raises(api_mutation_error)
                   .in_sequence(sync_sequence)

      @plaid_client.expects(:transactions_sync)
                   .with { |req| req.cursor == 'next-cursor' && req.access_token == @access_token }
                   .raises(api_mutation_error)
                   .times(Api::MAX_RETRIES)
                   .in_sequence(sync_sequence)

      assert_raises(Api::TransactionSyncError) do
        service.transactions_sync('next-cursor')
      end
    end
  end
end
