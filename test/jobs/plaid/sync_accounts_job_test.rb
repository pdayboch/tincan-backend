# frozen_string_literal: true

require 'test_helper'

module Plaid
  class SyncAccountsJobTest < ActiveSupport::TestCase
    test 'processes items with accounts_synced_at nil' do
      item = plaid_items(:accounts_synced_nil)

      mock_sync_accounts_service = mock('sync-accounts-service')
      PlaidServices::Accounts::SyncService.expects(:new)
                                          .at_least_once
                                          .returns(mock_sync_accounts_service)

      PlaidServices::Accounts::SyncService.expects(:new)
                                          .with { |arg| arg.id == item.id }
                                          .returns(mock_sync_accounts_service)

      mock_sync_accounts_service.expects(:call)
                                .at_least_once
                                .returns(true)

      Plaid::SyncAccountsJob.new.perform
    end

    test 'processes items with accounts_synced_at older than 6 hours' do
      item = plaid_items(:accounts_synced_older_6_h)

      mock_sync_accounts_service = mock('sync-accounts-service')
      PlaidServices::Accounts::SyncService.expects(:new)
                                          .at_least_once
                                          .returns(mock_sync_accounts_service)

      PlaidServices::Accounts::SyncService.expects(:new)
                                          .with { |arg| arg.id == item.id }
                                          .returns(mock_sync_accounts_service)

      mock_sync_accounts_service.expects(:call)
                                .at_least_once
                                .returns(true)

      Plaid::SyncAccountsJob.new.perform
    end

    test 'processes only override_item_ids when specified' do
      process_item = plaid_items(:just_synced)
      not_process_item = plaid_items(:accounts_synced_nil)

      mock_sync_accounts_service = mock('sync-accounts-service')

      PlaidServices::Accounts::SyncService.expects(:new)
                                          .with { |arg| arg.id == not_process_item.id }
                                          .never

      PlaidServices::Accounts::SyncService.expects(:new)
                                          .with { |arg| arg.id == process_item.id }
                                          .returns(mock_sync_accounts_service)

      mock_sync_accounts_service.expects(:call)
                                .returns(true)

      Plaid::SyncAccountsJob.new.perform([process_item.item_id])
    end

    test 'halts processing when plaid rate limit exceeded' do
      mock_sync_accounts_service = mock('sync-accounts-service')
      PlaidServices::Accounts::SyncService.expects(:new)
                                          .returns(mock_sync_accounts_service)

      mock_sync_accounts_service.expects(:call)
                                .raises(PlaidServices::Accounts::SyncService::PlaidApiRateLimitError)

      Rails.logger.expects(:warn).with('Plaid API rate limit exceeded. Stopping job.')

      Plaid::SyncAccountsJob.new.perform
    end

    test 'raises exception for plaid api error other than rate limit exceeded' do
      some_error = Plaid::ApiError.new(
        data: { 'error_type' => 'SERVER_ERROR' }
      )
      mock_sync_accounts_service = mock('sync-accounts-service')
      PlaidServices::Accounts::SyncService.expects(:new)
                                          .returns(mock_sync_accounts_service)

      mock_sync_accounts_service.expects(:call)
                                .raises(some_error)

      assert_raises Plaid::ApiError do
        Plaid::SyncAccountsJob.new.perform
      end
    end
  end
end
