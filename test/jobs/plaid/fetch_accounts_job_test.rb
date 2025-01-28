# frozen_string_literal: true

require 'test_helper'

module Plaid
  class FetchAccountsJobTest < ActiveSupport::TestCase
    setup do
      @mock_api = mock('plaid-api')
      PlaidServices::Api.stubs(:new).returns(@mock_api)

      @mock_account_response = Plaid::AccountsGetResponse.new(
        accounts: [
          {
            account_id: '12345',
            name: 'checking'
          }
        ]
      )
    end

    test 'processes items with accounts_synced_at nil' do
      item = plaid_items(:accounts_synced_nil)
      @mock_api.expects(:accounts)
               .at_least_once
               .returns(@mock_account_response)

      mock_sync_accounts_service = mock('sync-accounts-service')
      PlaidServices::SyncAccounts.expects(:new)
                                 .at_least_once
                                 .returns(mock_sync_accounts_service)

      PlaidServices::SyncAccounts.expects(:new)
                                 .with { |arg1, arg2| arg1.id == item.id && arg2 == @mock_account_response }
                                 .returns(mock_sync_accounts_service)

      mock_sync_accounts_service.expects(:call)
                                .at_least_once
                                .returns(true)

      Plaid::FetchAccountsJob.new.perform
    end

    test 'processes items with accounts_synced_at older than 24 hours' do
      item = plaid_items(:accounts_synced_older_24_h)
      @mock_api.expects(:accounts)
               .at_least_once
               .returns(@mock_account_response)

      mock_sync_accounts_service = mock('sync-accounts-service')
      PlaidServices::SyncAccounts.expects(:new)
                                 .at_least_once
                                 .returns(mock_sync_accounts_service)

      PlaidServices::SyncAccounts.expects(:new)
                                 .with { |arg1, arg2| arg1.id == item.id && arg2 == @mock_account_response }
                                 .returns(mock_sync_accounts_service)

      mock_sync_accounts_service.expects(:call)
                                .at_least_once
                                .returns(true)

      Plaid::FetchAccountsJob.new.perform
    end

    test 'processes only override_item_ids when specified' do
      process_item = plaid_items(:just_synced)
      not_process_item = plaid_items(:accounts_synced_nil)

      @mock_api.expects(:accounts)
               .returns(@mock_account_response)

      mock_sync_accounts_service = mock('sync-accounts-service')

      PlaidServices::SyncAccounts.expects(:new)
                                 .with { |arg1, _| arg1.id == not_process_item.id }
                                 .never

      PlaidServices::SyncAccounts.expects(:new)
                                 .with { |arg1, _| arg1.id == process_item.id }
                                 .returns(mock_sync_accounts_service)

      mock_sync_accounts_service.expects(:call)
                                .returns(true)

      Plaid::FetchAccountsJob.new.perform([process_item.item_id])
    end

    test 'halts processing when plaid rate limit exceeded' do
      rate_limit_error = Plaid::ApiError.new(
        data: { 'error_type' => FetchAccountsJob::RATE_LIMIT_EXCEEDED }
      )
      @mock_api.expects(:accounts)
               .raises(rate_limit_error)

      Rails.logger.expects(:warn).with('Plaid API rate limit exceeded. Stopping job.')
      PlaidServices::SyncAccounts.expects(:new).never

      Plaid::FetchAccountsJob.new.perform
    end

    test 'raises exception for plaid api error other than rate limit exceeded' do
      some_error = Plaid::ApiError.new(
        data: { 'error_type' => 'SERVER_ERROR' }
      )
      @mock_api.expects(:accounts)
               .raises(some_error)

      assert_raises Plaid::ApiError do
        Plaid::FetchAccountsJob.new.perform
      end
    end
  end
end
