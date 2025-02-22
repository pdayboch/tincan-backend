# frozen_string_literal: true

require 'test_helper'

module Plaid
  class SyncTransactionsJobTest < ActiveSupport::TestCase
    test 'processes items with transactions_synced_at nil' do
      item = plaid_items(:transactions_synced_nil)

      mock_sync_service = mock('sync-service')
      PlaidServices::Transactions::SyncService.expects(:new)
                                              .at_least_once
                                              .returns(mock_sync_service)

      PlaidServices::Transactions::SyncService.expects(:new)
                                              .with { |arg| arg.id == item.id }
                                              .returns(mock_sync_service)

      mock_sync_service.expects(:call)
                       .at_least_once
                       .returns(true)

      Plaid::SyncTransactionsJob.new.perform
    end

    test 'processes items with transactions_synced_at older than 12 hours' do
      item = plaid_items(:transactions_synced_older_12_h)

      mock_sync_service = mock('sync-service')
      PlaidServices::Transactions::SyncService.expects(:new)
                                              .at_least_once
                                              .returns(mock_sync_service)

      PlaidServices::Transactions::SyncService.expects(:new)
                                              .with { |arg| arg.id == item.id }
                                              .returns(mock_sync_service)

      mock_sync_service.expects(:call)
                       .at_least_once
                       .returns(true)

      Plaid::SyncTransactionsJob.new.perform
    end

    test 'does not process items without accounts synced' do
      item = plaid_items(:new_item)

      mock_sync_service = mock('sync-service')
      PlaidServices::Transactions::SyncService.expects(:new)
                                              .at_least_once
                                              .returns(mock_sync_service)

      PlaidServices::Transactions::SyncService.expects(:new)
                                              .with { |arg| arg.id == item.id }
                                              .never

      mock_sync_service.expects(:call)
                       .at_least_once
                       .returns(true)

      Plaid::SyncTransactionsJob.new.perform
    end

    test 'processes only override_item_ids when specified' do
      process_item = plaid_items(:transactions_synced_older_12_h)
      not_process_item = plaid_items(:transactions_synced_nil)

      mock_sync_service = mock('sync-service')

      PlaidServices::Transactions::SyncService.expects(:new)
                                              .with { |arg| arg.id == process_item.id }
                                              .returns(mock_sync_service)

      PlaidServices::Transactions::SyncService.expects(:new)
                                              .with { |arg| arg.id == not_process_item.id }
                                              .never

      mock_sync_service.expects(:call)
                       .at_least_once
                       .returns(true)

      Plaid::SyncTransactionsJob.new.perform([process_item.item_id])
    end

    test 'halts processing when plaid rate limit exceeded' do
      mock_sync_service = mock('sync-service')
      PlaidServices::Transactions::SyncService.expects(:new)
                                              .returns(mock_sync_service)

      mock_sync_service.expects(:call)
                       .raises(Plaid::ApiRateLimitError)

      Rails.logger.expects(:warn).with('Plaid API rate limit exceeded. Stopping job.')

      Plaid::SyncTransactionsJob.new.perform
    end

    test 'raises exception for plaid api error other than rate limit exceeded' do
      some_error = Plaid::ApiError.new(
        data: { 'error_type' => 'SERVER_ERROR' }
      )
      mock_sync_service = mock('sync-service')
      PlaidServices::Transactions::SyncService.expects(:new)
                                              .returns(mock_sync_service)

      mock_sync_service.expects(:call)
                       .raises(some_error)

      assert_raises Plaid::ApiError do
        Plaid::SyncTransactionsJob.new.perform
      end
    end
  end
end
