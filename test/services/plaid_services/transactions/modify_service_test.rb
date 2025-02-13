# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  module Transactions
    class ModifyServiceTest < ActiveSupport::TestCase
      test 'modifies transaction with correct attributes' do
        item = plaid_items(:with_multiple_accounts)
        account = item.accounts.first
        account.transactions.create!(
          transaction_date: Date.new(2024, 12, 12),
          description: 'first description',
          amount: 12.34,
          plaid_transaction_id: 'transaction-id',
          pending: true
        )

        transaction = Plaid::Transaction.new(
          account_id: account.plaid_account_id,
          amount: 54.32,
          authorized_date: Date.new(2025, 1, 2),
          date: Date.new(2025, 1, 3),
          name: 'second description',
          pending: false,
          transaction_id: 'transaction-id',
          personal_finance_category: Plaid::PersonalFinanceCategory.new(
            primary: 'FOOD_AND_DRINK',
            detailed: 'FOOD_AND_DRINK_FAST_FOOD',
            confidence_level: 'VERY_HIGH'
          )
        )

        ModifyService.new(account, transaction).call

        fast_food = subcategories(:fast_food)
        updated_transaction = account.transactions
                                     .find_by(plaid_transaction_id: 'transaction-id')

        assert_equal 'transaction-id', updated_transaction.plaid_transaction_id
        assert_equal 'second description', updated_transaction.description
        assert_equal 'second description', updated_transaction.statement_description
        assert_equal 54.32, updated_transaction.amount
        assert_equal Date.new(2025, 1, 2), updated_transaction.transaction_date
        assert_equal Date.new(2025, 1, 2), updated_transaction.statement_transaction_date
        assert_equal fast_food.id, updated_transaction.subcategory.id
        assert_not updated_transaction.pending
      end

      test 'modifies transaction with correct attributes when no authorized_date' do
        item = plaid_items(:with_multiple_accounts)
        account = item.accounts.first
        account.transactions.create!(
          transaction_date: Date.new(2024, 12, 12),
          description: 'first description',
          amount: 12.34,
          plaid_transaction_id: 'transaction-id',
          pending: true
        )

        transaction = Plaid::Transaction.new(
          account_id: account.plaid_account_id,
          amount: 54.32,
          date: Date.new(2025, 1, 3),
          name: 'second description',
          pending: false,
          transaction_id: 'transaction-id',
          personal_finance_category: Plaid::PersonalFinanceCategory.new(
            primary: 'FOOD_AND_DRINK',
            detailed: 'FOOD_AND_DRINK_FAST_FOOD',
            confidence_level: 'VERY_HIGH'
          )
        )

        ModifyService.new(account, transaction).call

        fast_food = subcategories(:fast_food)
        updated_transaction = account.transactions
                                     .find_by(plaid_transaction_id: 'transaction-id')

        assert_equal 'transaction-id', updated_transaction.plaid_transaction_id
        assert_equal 'second description', updated_transaction.description
        assert_equal 'second description', updated_transaction.statement_description
        assert_equal 54.32, updated_transaction.amount
        assert_equal Date.new(2025, 1, 3), updated_transaction.transaction_date
        assert_equal Date.new(2025, 1, 3), updated_transaction.statement_transaction_date
        assert_equal fast_food.id, updated_transaction.subcategory.id
        assert_not updated_transaction.pending
      end

      test 'uses category_mapper instance if passed in as option' do
        item = plaid_items(:with_multiple_accounts)
        account = item.accounts.first
        account.transactions.create!(
          transaction_date: Date.new(2024, 12, 12),
          description: 'first description',
          amount: 12.34,
          plaid_transaction_id: 'transaction-id',
          pending: true
        )

        transaction = Plaid::Transaction.new(
          account_id: account.plaid_account_id,
          amount: 54.32,
          authorized_date: Date.new(2025, 1, 2),
          date: Date.new(2025, 1, 3),
          name: 'second description',
          pending: false,
          transaction_id: 'transaction-id',
          personal_finance_category: Plaid::PersonalFinanceCategory.new(
            primary: 'FOOD_AND_DRINK',
            detailed: 'FOOD_AND_DRINK_FAST_FOOD',
            confidence_level: 'VERY_HIGH'
          )
        )

        fast_food = subcategories(:fast_food)
        mapper = Plaid::CategoryMapper.new
        mapper.expects(:map)
              .with('FOOD_AND_DRINK_FAST_FOOD')
              .returns([fast_food.category, fast_food])

        ModifyService.new(account, transaction, category_mapper: mapper).call
        updated_transaction = account.transactions
                                     .find_by(plaid_transaction_id: 'transaction-id')

        assert_equal fast_food.id, updated_transaction.subcategory_id
      end

      test 'raises RecordNotFound when plaid_transaction_id not found' do
        item = plaid_items(:with_multiple_accounts)
        account = item.accounts.first

        transaction = Plaid::Transaction.new(
          account_id: account.plaid_account_id,
          amount: 54.32,
          authorized_date: Date.new(2025, 1, 2),
          date: Date.new(2025, 1, 3),
          name: 'description',
          pending: false,
          transaction_id: 'non-existant'
        )

        assert_raises(ActiveRecord::RecordNotFound) do
          ModifyService.new(account, transaction).call
        end
      end
    end
  end
end
