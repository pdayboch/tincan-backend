# frozen_string_literal: true

# Take a plaid::Transaction class and create a new Transaction under the account
module PlaidServices
  module Transactions
    class CreateService
      def initialize(account, plaid_transaction, category_mapper: nil)
        @account = account
        @plaid_transaction = plaid_transaction
        @category_mapper = category_mapper || ::Plaid::CategoryMapper.new
      end

      def call
        category, subcategory = @category_mapper.map(plaid_category)

        @account.transactions.create!(
          plaid_transaction_id: @plaid_transaction.transaction_id,
          transaction_date: date,
          statement_transaction_date: date,
          amount: @plaid_transaction.amount,
          description: description,
          statement_description: description,
          pending: @plaid_transaction.pending,
          category_id: category.id,
          subcategory_id: subcategory.id
        )
      end

      private

      def date
        @plaid_transaction.authorized_date || @plaid_transaction.date
      end

      def description
        @plaid_transaction.name
      end

      def plaid_category
        return nil if @plaid_transaction.personal_finance_category.nil?

        @plaid_transaction.personal_finance_category.detailed
      end
    end
  end
end
