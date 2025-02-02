# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  module Transactions
    class SyncServiceTest < ActiveSupport::TestCase
      setup do
        @mock_api = mock('plaid-api')
        PlaidServices::Api.stubs(:new).returns(@mock_api)
      end

      test 'correctly updates item transaction_sync_cursor' do
        item = plaid_items(:new_item)

        @mock_api.expects(:transactions_sync)
                 .returns(
                   added: [],
                   modified: [],
                   removed: [],
                   next_cursor: 'next-cursor-2'
                 )

        SyncService.new(item).call

        assert 'next-cursor-2', item.reload.transaction_sync_cursor
      end

      test 'marks item transactions_synced_at after successful sync' do
        item = plaid_items(:new_item)

        @mock_api.expects(:transactions_sync)
                 .returns(
                   added: [],
                   modified: [],
                   removed: [],
                   next_cursor: 'next-cursor-2'
                 )

        Timecop.freeze(Time.zone.local(2025, 1, 31, 12, 0, 0)) do
          SyncService.new(item).call
          assert_equal Time.zone.local(2025, 1, 31, 12, 0, 0), item.transactions_synced_at
        end
      end

      test 'raises Plaid::ApiRateLimitError when rate limit exceeded' do
        item = plaid_items(:new_item)

        rate_limit_error = Plaid::ApiError.new(
          data: { 'error_type' => Plaid::ApiRateLimitError::ERROR_TYPE }
        )
        @mock_api.expects(:transactions_sync)
                 .raises(rate_limit_error)

        assert_raises Plaid::ApiRateLimitError do
          SyncService.new(item).call
        end
      end

      test 'raises exception for non-rate limit errors' do
        item = plaid_items(:new_item)

        some_error = Plaid::ApiError.new(
          data: { 'error_type' => 'SERVER_ERROR' }
        )
        @mock_api.expects(:transactions_sync)
                 .raises(some_error)

        assert_raises Plaid::ApiError do
          SyncService.new(item).call
        end
      end

      test 'added correctly calls the Transaction::CreateService' do
        item = plaid_items(:with_multiple_accounts)
        account1 = item.accounts.order(:id).first
        account2 = item.accounts.order(:id).last

        transactions = [
          Plaid::Transaction.new(
            {
              account_id: account1.plaid_account_id,
              amount: 6.33,
              authorized_date: Date.new(2025, 1, 1),
              category: %w[Travel Taxi],
              date: Date.new(2025, 1, 2),
              name: 'Uber 072515 SF**POOL**',
              pending: false,
              transaction_id: 'transaction-1-id'
            }
          ),
          Plaid::Transaction.new(
            {
              account_id: account2.plaid_account_id,
              amount: 5.4,
              category: ['Food and Drink', 'Restaurants'],
              date: Date.new(2024, 2, 23),
              name: "McDonald's",
              pending: true,
              transaction_id: 'transaction-2-id'
            }
          )
        ]

        @mock_api.expects(:transactions_sync)
                 .returns(
                   added: transactions,
                   modified: [],
                   removed: [],
                   next_cursor: 'next-cursor'
                 )

        mock_create_service = mock('create-service')

        CreateService.expects(:new).with do |arg1, arg2|
          arg1.plaid_account_id == account1.plaid_account_id && arg2 == transactions[0]
        end
        .times(1)
        .returns(mock_create_service)

        CreateService.expects(:new).with do |arg1, arg2|
          arg1.plaid_account_id == account2.plaid_account_id && arg2 == transactions[1]
        end
        .times(1)
        .returns(mock_create_service)

        mock_create_service.expects(:call).times(2).returns(true)

        SyncService.new(item).call
      end

      test 'added logs and skips any accounts not found' do
        item = plaid_items(:with_multiple_accounts)
        account = item.accounts.first

        transactions = [
          Plaid::Transaction.new(
            account_id: 'non-existant-account',
            amount: 6.33,
            authorized_date: Date.new(2025, 1, 1),
            category: %w[Travel Taxi],
            date: Date.new(2025, 1, 2),
            name: 'Uber 072515 SF**POOL**',
            pending: false,
            transaction_id: 'transaction-1-id'
          ),
          Plaid::Transaction.new(
            account_id: account.plaid_account_id,
            amount: 6.33,
            authorized_date: Date.new(2025, 1, 1),
            category: %w[Travel Taxi],
            date: Date.new(2025, 1, 2),
            name: 'Uber 072515 SF**POOL**',
            pending: false,
            transaction_id: 'transaction-1-id'
          )
        ]

        @mock_api.expects(:transactions_sync)
                 .returns(
                   added: transactions,
                   modified: [],
                   removed: [],
                   next_cursor: 'next-cursor'
                 )

        expected_msg = 'Account: non-existant-account not found when attempting to create transactions.'
        Rails.logger.expects(:error).with(expected_msg)

        assert_difference 'account.transactions.count', 1 do
          SyncService.new(item).call
        end
      end

      test 'added logs and skips when duplicate plaid_transaction_id' do
        item = plaid_items(:with_multiple_accounts)
        account = item.accounts.first
        account.transactions.create(
          description: 'existing transaction',
          amount: 12.34,
          transaction_date: Date.new(2024, 1, 1),
          plaid_transaction_id: 'existing-id'
        )

        transactions = [
          Plaid::Transaction.new(
            account_id: account.plaid_account_id,
            transaction_id: 'existing-id',
            amount: 12.34,
            name: 'a duplicate transaction',
            authorized_date: Date.new(2024, 1, 2),
            pending: false
          ),
          Plaid::Transaction.new(
            account_id: account.plaid_account_id,
            transaction_id: 'non-existing-id',
            amount: 45.67,
            name: 'a new transaction',
            authorized_date: Date.new(2024, 1, 3),
            pending: false
          )
        ]

        @mock_api.expects(:transactions_sync)
                 .returns(
                   added: transactions,
                   modified: [],
                   removed: [],
                   next_cursor: 'next-cursor'
                 )

        msg = 'Transactions::Sync attempted to create transaction with a ' \
              "duplicate plaid_transaction_id: existing-id in account: #{account.id} " \
              'and creation was skipped.'
        Rails.logger.expects(:error).with(msg)

        SyncService.new(item).call

        assert_not_nil account
          .reload
          .transactions
          .find_by(plaid_transaction_id: 'non-existing-id')
      end
    end
  end
end
