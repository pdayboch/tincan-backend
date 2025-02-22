# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  module Transactions
    module Sync
      class RemovedHandlerTest < ActiveSupport::TestCase
        setup do
          @mock_api = mock('plaid-api')
          PlaidServices::Api.stubs(:new).returns(@mock_api)
        end

        test 'correctly calls the Transactions::RemoveService' do
          item = plaid_items(:with_multiple_accounts)
          account1 = item.accounts.order(:id).first
          account2 = item.accounts.order(:id).last

          tx1 = account1.transactions.create!(
            plaid_transaction_id: 'transaction-1-id',
            amount: 12.34,
            description: 'test transaction',
            transaction_date: Date.new(2025, 1, 1)
          )

          tx2 = account2.transactions.create!(
            plaid_transaction_id: 'transaction-2-id',
            amount: 34.56,
            description: 'test transaction 2',
            transaction_date: Date.new(2025, 2, 1)
          )

          transactions = [
            Plaid::RemovedTransaction.new(
              account_id: account1.plaid_account_id,
              transaction_id: tx1.plaid_transaction_id
            ),
            Plaid::RemovedTransaction.new(
              account_id: account2.plaid_account_id,
              transaction_id: tx2.plaid_transaction_id
            )
          ]

          @mock_api.expects(:transactions_sync)
                   .returns(
                     accounts: [],
                     added: [],
                     modified: [],
                     removed: transactions,
                     next_cursor: 'next-cursor'
                   )

          assert_difference 'account1.transactions.count', -1 do
            assert_difference 'account2.transactions.count', -1 do
              SyncService.new(item).call
            end
          end

          assert_not Transaction.exists?(tx1.id)
          assert_not Transaction.exists?(tx2.id)
        end

        test 'logs and skips any accounts not found' do
          item = plaid_items(:with_multiple_accounts)
          account = item.accounts.first

          account.transactions.create!(
            plaid_transaction_id: 'transaction-2-id',
            amount: 34.56,
            description: 'test transaction',
            transaction_date: Date.new(2025, 2, 1)
          )

          transactions = [
            Plaid::RemovedTransaction.new(
              account_id: 'non-existant-account',
              transaction_id: 'transaction-1-id'
            ),
            Plaid::RemovedTransaction.new(
              account_id: account.plaid_account_id,
              transaction_id: 'transaction-2-id'
            )
          ]

          @mock_api.expects(:transactions_sync)
                   .returns(
                     accounts: [],
                     added: [],
                     modified: [],
                     removed: transactions,
                     next_cursor: 'next-cursor'
                   )

          expected_msg = 'Plaid account: non-existant-account not found when ' \
                         'attempting to remove Plaid transactions with IDs: ' \
                         'transaction-1-id'
          Rails.logger.expects(:error).with(expected_msg)

          assert_difference 'account.transactions.count', -1 do
            SyncService.new(item).call
          end
        end

        test 'logs deleted request and actual deleted transactions' do
          item = plaid_items(:with_multiple_accounts)
          account = item.accounts.first

          account.transactions.create!(
            plaid_transaction_id: 'transaction-2-id',
            amount: 34.56,
            description: 'test transaction',
            transaction_date: Date.new(2025, 2, 1)
          )

          transactions = [
            Plaid::RemovedTransaction.new(
              account_id: account.plaid_account_id,
              transaction_id: 'non-existent-id'
            ),
            Plaid::RemovedTransaction.new(
              account_id: account.plaid_account_id,
              transaction_id: 'transaction-2-id'
            )
          ]

          @mock_api.expects(:transactions_sync)
                   .returns(
                     accounts: [],
                     added: [],
                     modified: [],
                     removed: transactions,
                     next_cursor: 'next-cursor'
                   )

          expected_msg = 'Plaid Transactions SyncService requested to delete: ' \
                         "#{transactions.map(&:transaction_id).join(', ')}. " \
                         'Actual deleted transactions: transaction-2-id'
          Rails.logger.expects(:info).with(expected_msg)

          SyncService.new(item).call
        end
      end
    end
  end
end
