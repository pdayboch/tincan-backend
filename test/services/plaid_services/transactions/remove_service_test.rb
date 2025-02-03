# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  module Transactions
    class RemoveServiceTest < ActiveSupport::TestCase
      test 'successfully destroys transactions' do
        item = plaid_items(:with_multiple_accounts)
        account = item.accounts.first
        transaction_id = 'plaid-transaction-id'
        account.transactions.create!(
          plaid_transaction_id: transaction_id,
          amount: 12.34,
          description: 'test transaction',
          transaction_date: Date.new(2025, 1, 1)
        )

        removed_transactions = [
          Plaid::RemovedTransaction.new(
            account_id: account.plaid_account_id,
            transaction_id: transaction_id
          )
        ]

        RemoveService.new(account, removed_transactions).call

        assert_nil account.reload.transactions.find_by(plaid_transaction_id: transaction_id)
      end

      test 'returns array of deleted ids' do
        item = plaid_items(:with_multiple_accounts)
        account = item.accounts.first
        transaction_id = 'plaid-transaction-id'
        account.transactions.create!(
          plaid_transaction_id: transaction_id,
          amount: 12.34,
          description: 'test transaction',
          transaction_date: Date.new(2025, 1, 1)
        )

        removed_transactions = [
          Plaid::RemovedTransaction.new(
            account_id: account.plaid_account_id,
            transaction_id: transaction_id
          ),
          Plaid::RemovedTransaction.new(
            account_id: account.plaid_account_id,
            transaction_id: 'non-existent-id'
          )
        ]

        deleted_ids = RemoveService.new(account, removed_transactions).call
        assert_includes deleted_ids, transaction_id
      end

      test 'returns empty array when plaid_transactions is empty' do
        account = accounts(:plaid_savings_account)
        deleted_ids = RemoveService.new(account, []).call
        assert_equal [], deleted_ids
      end
    end
  end
end
