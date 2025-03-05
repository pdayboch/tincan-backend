# frozen_string_literal: true

module PlaidServices
  class TransactionAmountMapper
    # Plaid Official documentation:
    # For all products except Income: Positive values when
    # money moves out of the account; negative values when
    # money moves in. For example, debit card purchases are
    # positive; credit card payments, direct deposits, and
    # refunds are negative. For Income endpoints, values are
    # positive when representing income.

    ACCOUNT_TYPES_NEGATE_AMOUNT = ['cash', 'investments', 'credit cards'].freeze

    def initialize(account)
      @account = account
    end

    def map(transaction_data)
      amount = transaction_data.amount
      return amount unless ACCOUNT_TYPES_NEGATE_AMOUNT.include?(@account.account_subtype)

      -1.0 * amount
    end
  end
end
