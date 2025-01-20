# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  class ApiTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)
      @plaid_client = mock('plaid_client')
      @access_token = 'test_access_token'

      @error_response = {
        'error_type' => 'API_ERROR',
        'error_code' => 'INTERNAL_SERVER_ERROR',
        'error_message' => 'An internal server error occurred',
        'request_id' => '12345',
        'documentation_url' => 'https://plaid.com/docs'
      }.to_json

      @expected_log = 'Plaid Service Error: ' \
                      'type = API_ERROR ' \
                      'code = INTERNAL_SERVER_ERROR ' \
                      'message = An internal server error occurred ' \
                      'request_id = 12345 ' \
                      'error_code_reason =  ' \
                      'docs = https://plaid.com/docs'

      Plaid::ApiClient.stubs(:new).returns(@plaid_client)
      Plaid::PlaidApi.stubs(:new).returns(@plaid_client)
    end

    test 'initializes with correct environment in development' do
      Rails.env.stubs(:production?).returns(false)

      configuration = nil
      Plaid::Configuration.any_instance.stubs(:server_index=).with do |index|
        configuration = index
        true
      end

      PlaidServices::Api.new
      assert_equal Plaid::Configuration::Environment['sandbox'], configuration
    end

    test 'initializes with correct environment in production' do
      Rails.env.stubs(:production?).returns(true)

      configuration = nil
      Plaid::Configuration.any_instance.stubs(:server_index=).with do |index|
        configuration = index
        true
      end

      PlaidServices::Api.new
      assert_equal Plaid::Configuration::Environment['production'], configuration
    end

    test 'creates link token successfully' do
      expected_token = 'test-link-token'
      link_token_response = mock('link_token_response')
      link_token_response.stubs(:link_token).returns(expected_token)

      @plaid_client.expects(:link_token_create)
                   .with(instance_of(Plaid::LinkTokenCreateRequest))
                   .returns(link_token_response)

      token = PlaidServices::Api.create_link_token(@user)
      assert_equal expected_token, token
    end

    test 'handles link token creation error' do
      api_error = Plaid::ApiError.new(response_body: @error_response)

      Rails.logger.expects(:error).with(@expected_log)
      @plaid_client.expects(:link_token_create).raises(api_error)

      assert_raises Plaid::ApiError do
        PlaidServices::Api.create_link_token(@user)
      end
    end

    test 'exchanges public token successfully' do
      public_token = 'test_public_token'
      exchange_response = mock('exchange_response')
      @plaid_client.expects(:item_public_token_exchange)
                   .with(instance_of(Plaid::ItemPublicTokenExchangeRequest))
                   .returns(exchange_response)

      response = PlaidServices::Api.public_token_exchange(public_token)

      assert_equal exchange_response, response
    end

    test 'handles exchange public token error' do
      api_error = Plaid::ApiError.new(response_body: @error_response)

      Rails.logger.expects(:error).with(@expected_log)
      @plaid_client.expects(:item_public_token_exchange).raises(api_error)

      assert_raises Plaid::ApiError do
        PlaidServices::Api.public_token_exchange(@user)
      end
    end

    test 'gets item successfully' do
      service = PlaidServices::Api.new(@access_token)
      item_response = mock('item_response')

      @plaid_client.expects(:item_get)
                   .with(instance_of(Plaid::ItemGetRequest))
                   .returns(item_response)

      response = service.show

      assert_equal item_response, response
    end

    test 'handles get item error' do
      api_error = Plaid::ApiError.new(response_body: @error_response)

      Rails.logger.expects(:error).with(@expected_log)
      @plaid_client.expects(:item_get).raises(api_error)

      assert_raises Plaid::ApiError do
        PlaidServices::Api.new(@access_token).show
      end
    end

    test 'removes item successfully' do
      service = PlaidServices::Api.new(@access_token)
      remove_response = mock('remove_response')

      @plaid_client.expects(:item_remove)
                   .with(instance_of(Plaid::ItemRemoveRequest))
                   .returns(remove_response)

      response = service.destroy

      assert_equal remove_response, response
    end

    test 'handles remove item error' do
      api_error = Plaid::ApiError.new(response_body: @error_response)

      Rails.logger.expects(:error).with(@expected_log)
      @plaid_client.expects(:item_remove).raises(api_error)

      assert_raises Plaid::ApiError do
        PlaidServices::Api.new(@access_token).destroy
      end
    end

    test 'retrieves accounts successfully' do
      service = PlaidServices::Api.new(@access_token)
      accounts_response = mock('accounts_response')

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
        PlaidServices::Api.new(@access_token).accounts
      end
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
