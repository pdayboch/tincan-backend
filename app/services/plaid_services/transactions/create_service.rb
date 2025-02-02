# frozen_string_literal: true

# Take a plaid::Transaction class and create a new Transaction under the account
module PlaidServices
  module Transactions
    class CreateService
      def initialize(account, plaid_transaction)
        @account = account
        @plaid_transaction = plaid_transaction
      end

      def call
        @account.transactions.create!(
          plaid_transaction_id: @plaid_transaction.transaction_id,
          transaction_date: date,
          statement_transaction_date: date,
          amount: @plaid_transaction.amount,
          description: description,
          statement_description: description,
          pending: @plaid_transaction.pending
        )
      end

      private

      def date
        @plaid_transaction.authorized_date || @plaid_transaction.date
      end

      def description
        @plaid_transaction.name
      end
    end
  end
end
