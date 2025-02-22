# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  module Transactions
    module Sync
      class AddedHandlerTest < ActiveSupport::TestCase
        setup do
          @mock_api = mock('plaid-api')
          PlaidServices::Api.stubs(:new).returns(@mock_api)
        end

        test 'correctly calls the Transactions::CreateService' do
          item = plaid_items(:with_multiple_accounts)
          account1 = item.accounts.order(:id).first
          account2 = item.accounts.order(:id).last

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

        test 'creates and logs accounts not found when plaid data present' do
          item = plaid_items(:no_accounts)

          accounts = [
            Plaid::AccountBase.new(
              account_id: 'non-existant-account',
              balances: Plaid::AccountBalance.new(current: 12.55),
              name: 'account-name',
              type: 'depository',
              subtype: 'checking'
            )
          ]

          transactions = [
            Plaid::Transaction.new(
              account_id: 'non-existant-account',
              amount: 6.33,
              authorized_date: Date.new(2025, 1, 1),
              date: Date.new(2025, 1, 2),
              name: 'Transaction 1',
              pending: false,
              transaction_id: 'transaction-1-id'
            )
          ]

          @mock_api.expects(:transactions_sync)
                   .returns(
                     accounts: accounts,
                     added: transactions,
                     modified: [],
                     removed: [],
                     next_cursor: 'next-cursor'
                   )

          expected_msg = 'Creating new Plaid account non-existant-account ' \
                         'discovered during transaction sync'
          Rails.logger.expects(:info).with(expected_msg)

          assert_difference 'Account.count', 1 do
            assert_difference 'Transaction.count', 1 do
              SyncService.new(item).call
            end
          end

          new_account = item.accounts.find_by(plaid_account_id: 'non-existant-account')
          assert_not_nil new_account
        end

        test 'logs and skips accounts not found when plaid data not present' do
          item = plaid_items(:no_accounts)

          transactions = [
            Plaid::Transaction.new(
              account_id: 'non-existant-account',
              amount: 6.33,
              authorized_date: Date.new(2025, 1, 1),
              date: Date.new(2025, 1, 2),
              name: 'Transaction 1',
              pending: false,
              transaction_id: 'transaction-1-id'
            )
          ]

          @mock_api.expects(:transactions_sync)
                   .returns(
                     accounts: [],
                     added: transactions,
                     modified: [],
                     removed: [],
                     next_cursor: 'next-cursor'
                   )

          expected_msg = 'Plaid Account non-existant-account not found locally ' \
                         'and not present in transaction sync response'
          Rails.logger.expects(:error).with(expected_msg)

          assert_no_difference 'Account.count' do
            assert_no_difference 'Transaction.count' do
              SyncService.new(item).call
            end
          end
        end

        test 'logs and skips when account belongs to another item' do
          item = plaid_items(:no_accounts)
          item2 = plaid_items(:with_multiple_accounts)
          existing_account = item2.accounts.first

          accounts = [
            Plaid::AccountBase.new(
              account_id: existing_account.plaid_account_id,
              balances: Plaid::AccountBalance.new(current: 12.55),
              name: 'account-name',
              type: 'depository',
              subtype: 'checking'
            )
          ]

          transactions = [
            Plaid::Transaction.new(
              account_id: existing_account.plaid_account_id,
              amount: 6.33,
              authorized_date: Date.new(2025, 1, 1),
              date: Date.new(2025, 1, 2),
              name: 'Transaction 1',
              pending: false,
              transaction_id: 'transaction-1-id'
            )
          ]

          @mock_api.expects(:transactions_sync)
                   .returns(
                     accounts: accounts,
                     added: transactions,
                     modified: [],
                     removed: [],
                     next_cursor: 'next-cursor'
                   )

          expected_msg1 = 'PlaidServices::Accounts::Create - ' \
                          'Attempted to create a Plaid account which already exists: ' \
                          "plaid_account_id: #{existing_account.plaid_account_id}"
          Rails.logger.expects(:error).with(expected_msg1)

          expected_msg2 = 'Attempted to create account with plaid_account_id: ' \
                          "#{existing_account.plaid_account_id} but it exists " \
                          'under another item'
          Rails.logger.expects(:error).with(expected_msg2)

          assert_no_difference 'Account.count' do
            assert_no_difference 'Transaction.count' do
              SyncService.new(item).call
            end
          end
        end

        test 'logs and skips when duplicate plaid_transaction_id' do
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
            )
          ]

          @mock_api.expects(:transactions_sync)
                   .returns(
                     accounts: [],
                     added: transactions,
                     modified: [],
                     removed: [],
                     next_cursor: 'next-cursor'
                   )

          msg = 'Transactions::Sync attempted to create transaction with a ' \
                "duplicate plaid_transaction_id: existing-id in account: #{account.id} " \
                'and creation was skipped.'
          Rails.logger.expects(:error).with(msg)

          assert_no_difference 'Transaction.count' do
            SyncService.new(item).call
          end
        end
      end
    end
  end
end
