# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  module Transactions
    module Sync
      class ModifiedHandlerTest < ActiveSupport::TestCase
        setup do
          @mock_api = mock('plaid-api')
          PlaidServices::Api.stubs(:new).returns(@mock_api)
        end

        test 'modified correctly calls the Transactions::ModifyService' do
          item = plaid_items(:with_multiple_accounts)
          account1 = item.accounts.order(:id).first
          account2 = item.accounts.order(:id).last

          account1.transactions.create!(
            amount: 12.34,
            description: 'some transaction',
            transaction_date: Date.new(2025, 2, 1),
            plaid_transaction_id: 'transaction-1-id'
          )

          account2.transactions.create!(
            amount: 56.78,
            description: 'some transaction 2',
            transaction_date: Date.new(2025, 2, 3),
            plaid_transaction_id: 'transaction-2-id'
          )

          transactions = [
            Plaid::Transaction.new(
              account_id: account1.plaid_account_id,
              amount: 6.33,
              authorized_date: Date.new(2025, 1, 1),
              date: Date.new(2025, 1, 2),
              name: 'Uber 072515 SF**POOL**',
              pending: false,
              transaction_id: 'transaction-1-id'
            ),
            Plaid::Transaction.new(
              account_id: account2.plaid_account_id,
              amount: 5.4,
              date: Date.new(2024, 2, 23),
              name: "McDonald's",
              pending: true,
              transaction_id: 'transaction-2-id'
            )
          ]

          @mock_api.expects(:transactions_sync)
                   .returns(
                     accounts: [],
                     added: [],
                     modified: transactions,
                     removed: [],
                     next_cursor: 'next-cursor'
                   )

          mock_modify_service = mock('modify-service')

          ModifyService.expects(:new).with do |arg1, arg2|
            arg1.plaid_account_id == account1.plaid_account_id && arg2 == transactions[0]
          end
          .times(1)
          .returns(mock_modify_service)

          ModifyService.expects(:new).with do |arg1, arg2|
            arg1.plaid_account_id == account2.plaid_account_id && arg2 == transactions[1]
          end
          .times(1)
          .returns(mock_modify_service)

          mock_modify_service.expects(:call).times(2).returns(true)

          SyncService.new(item).call
        end

        test 'logs and skips any accounts not found' do
          item = plaid_items(:with_multiple_accounts)
          account = item.accounts.first

          account.transactions.create(
            plaid_transaction_id: 'transaction-2-id',
            amount: 6.33,
            description: 'old description',
            transaction_date: Date.new(2025, 1, 2)
          )

          transactions = [
            Plaid::Transaction.new(
              account_id: 'non-existant-account',
              amount: 6.33,
              authorized_date: Date.new(2025, 1, 1),
              date: Date.new(2025, 1, 2),
              name: 'Transaction 1',
              pending: false,
              transaction_id: 'transaction-1-id'
            ),
            Plaid::Transaction.new(
              account_id: account.plaid_account_id,
              amount: 6.33,
              authorized_date: Date.new(2025, 1, 2),
              date: Date.new(2025, 1, 3),
              name: 'Transaction 2',
              pending: false,
              transaction_id: 'transaction-2-id'
            )
          ]

          @mock_api.expects(:transactions_sync)
                   .returns(
                     accounts: [],
                     added: [],
                     modified: transactions,
                     removed: [],
                     next_cursor: 'next-cursor'
                   )

          expected_msg = 'Plaid account: non-existant-account not found when ' \
                         'attempting to modify transactions with IDs: transaction-1-id'
          Rails.logger.expects(:error).with(expected_msg)

          SyncService.new(item).call
        end

        test 'logs and skips when plaid_transaction_id not found' do
          item = plaid_items(:with_multiple_accounts)
          account = item.accounts.first

          transactions = [
            Plaid::Transaction.new(
              account_id: account.plaid_account_id,
              amount: 6.33,
              authorized_date: Date.new(2025, 1, 2),
              date: Date.new(2025, 1, 3),
              name: 'Transaction 2',
              pending: false,
              transaction_id: 'non-existent-id'
            )
          ]

          @mock_api.expects(:transactions_sync)
                   .returns(
                     accounts: [],
                     added: [],
                     modified: transactions,
                     removed: [],
                     next_cursor: 'next-cursor'
                   )

          expected_msg = 'Transactions::Sync attempted to modify a non-existent ' \
                         'Plaid transaction: non-existent-id in account: ' \
                         "#{account.id}. Modify was skipped."
          Rails.logger.expects(:error).with(expected_msg)

          SyncService.new(item).call
        end
      end
    end
  end
end
