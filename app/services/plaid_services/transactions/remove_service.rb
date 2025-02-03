# frozen_string_literal: true

module PlaidServices
  module Transactions
    # Service class to remove Plaid transaction records from an account
    #
    # This service takes an account and an array of Plaid RemovedTransaction
    # objects, and then destroys the corresponding transaction records from
    # the database
    class RemoveService
      # @param account [Account] The account associated with the transactions
      # @param plaid_transactions [Array<Plaid::RemovedTransaction>] An array of
      # Plaid transaction objects to be deleted.
      def initialize(account, plaid_transactions)
        @account = account
        @plaid_transactions = plaid_transactions
      end

      def call
        return [] if transaction_ids.empty?

        deleted_transactions = @account
                               .transactions
                               .where(plaid_transaction_id: transaction_ids)
                               .destroy_all

        deleted_transactions.map(&:plaid_transaction_id)
      end

      private

      def transaction_ids
        @transaction_ids ||= @plaid_transactions.map(&:transaction_id)
      end
    end
  end
end
