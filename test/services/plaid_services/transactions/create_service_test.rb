# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  module Transactions
    class CreateServiceTest < ActiveSupport::TestCase
      test 'creates transaction with correct attributes' do
        item = plaid_items(:with_multiple_accounts)
        account = item.accounts.first
        transaction = Plaid::Transaction.new(
          account_id: account.plaid_account_id,
          amount: 6.33,
          authorized_date: Date.new(2025, 1, 1),
          category: %w[Travel Taxi],
          date: Date.new(2025, 1, 2),
          name: 'Uber 072515 SF**POOL**',
          pending: false,
          transaction_id: 'transaction-1-id'
        )

        assert_difference 'account.transactions.count', 1 do
          CreateService.new(account, transaction).call
        end

        saved_transaction = account.transactions.find_by(plaid_transaction_id: 'transaction-1-id')
        assert_not_nil saved_transaction

        assert_equal 'transaction-1-id', saved_transaction.plaid_transaction_id
        assert_equal 'Uber 072515 SF**POOL**', saved_transaction.description
        assert_equal 'Uber 072515 SF**POOL**', saved_transaction.statement_description
        assert_equal 6.33, saved_transaction.amount
        assert_equal Date.new(2025, 1, 1), saved_transaction.transaction_date
        assert_equal Date.new(2025, 1, 1), saved_transaction.statement_transaction_date
        assert_not saved_transaction.pending
      end

      test 'creates transaction with correct attributes when no authorized_date' do
        item = plaid_items(:with_multiple_accounts)
        account = item.accounts.first
        transaction = Plaid::Transaction.new(
          {
            account_id: account.plaid_account_id,
            amount: 5.4,
            category: ['Food and Drink', 'Restaurants'],
            date: Date.new(2024, 2, 23),
            name: "McDonald's",
            pending: true,
            transaction_id: 'transaction-2-id'
          }
        )

        CreateService.new(account, transaction).call

        saved_transaction = account.transactions.find_by(plaid_transaction_id: 'transaction-2-id')
        assert_not_nil saved_transaction
        assert_equal 'transaction-2-id', saved_transaction.plaid_transaction_id
        assert_equal "McDonald's", saved_transaction.description
        assert_equal "McDonald's", saved_transaction.statement_description
        assert_equal 5.4, saved_transaction.amount
        assert_equal Date.new(2024, 2, 23), saved_transaction.transaction_date
        assert_equal Date.new(2024, 2, 23), saved_transaction.statement_transaction_date
        assert saved_transaction.pending
      end

      test 'Raises RecordNotUnique when creating duplicate plaid_transaction_id' do
        item = plaid_items(:with_multiple_accounts)
        account = item.accounts.first
        account.transactions.create(
          description: 'existing transaction',
          amount: 12.34,
          transaction_date: Date.new(2024, 1, 1),
          plaid_transaction_id: 'existing-id'
        )

        transaction = Plaid::Transaction.new(
          transaction_id: 'existing-id',
          amount: 12.34,
          name: 'a duplicate transaction',
          authorized_date: Date.new(2024, 1, 2),
          pending: false
        )

        assert_raises(ActiveRecord::RecordNotUnique) do
          CreateService.new(account, transaction).call
        end
      end
    end
  end
end
