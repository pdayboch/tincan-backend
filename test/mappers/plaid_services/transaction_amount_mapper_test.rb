# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  class TransactionAmountMapperTest < ActiveSupport::TestCase
    test 'negates amount for cash account' do
      account = accounts(:plaid_savings_account)

      transaction_data = Plaid::Transaction.new(
        amount: 15.23
      )

      amount = PlaidServices::TransactionAmountMapper.new(account)
                                                     .map(transaction_data)

      assert_equal(-15.23, amount)
    end

    test 'negates amount for credit card account' do
      account = accounts(:plaid_credit_account)

      transaction_data = Plaid::Transaction.new(
        amount: -100.51
      )

      amount = PlaidServices::TransactionAmountMapper.new(account)
                                                     .map(transaction_data)

      assert_equal(100.51, amount)
    end

    test 'does not negate amount for loan account' do
      account = accounts(:plaid_loan_account)

      transaction_data = Plaid::Transaction.new(
        amount: -1000.99
      )

      amount = PlaidServices::TransactionAmountMapper.new(account)
                                                     .map(transaction_data)

      assert_equal(-1000.99, amount)
    end
  end
end
