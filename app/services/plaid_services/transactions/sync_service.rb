# frozen_string_literal: true

module PlaidServices
  module Transactions
    class SyncService
      def initialize(plaid_item)
        @item = plaid_item
      end

      def call
        transactions_data = fetch_transactions_data
        handle_added(transactions_data)
        handle_modified(transactions_data)
        handle_removed(transactions_data)
        update_transaction_cursor(transactions_data)
        @item.mark_transactions_as_synced
      end

      private

      def handle_added(transactions_data)
        transactions_data[:added].group_by(&:account_id).each do |account_id, transactions|
          account = @item.accounts.find_by(plaid_account_id: account_id)
          if account.nil?
            error_msg = "Account: #{account_id} not found when attempting to create transactions."
            Rails.logger.error(error_msg)
            next
          end

          create_transactions(account, transactions)
        end
      end

      def create_transactions(account, transactions)
        transactions.each do |t|
          CreateService.new(account, t).call
        rescue ActiveRecord::RecordNotUnique
          error_msg = 'Transactions::Sync attempted to create transaction with a ' \
                      "duplicate plaid_transaction_id: #{t.transaction_id} in account: " \
                      "#{account.id} and creation was skipped."
          Rails.logger.error(error_msg)
          next
        end
      end

      def handle_modified(transactions_data)
        # TODO
      end

      def handle_removed(transactions_data)
        transactions_data[:removed].group_by(&:account_id).each do |account_id, transactions|
          account = @item.accounts.find_by(plaid_account_id: account_id)
          if account.nil?
            error_msg = "Account: #{account_id} not found when attempting to remove transactions."
            Rails.logger.error(error_msg)
            next
          end

          deleted_ids = RemoveService.new(account, transactions).call
          log_msg = 'Transactions SyncService requested to delete: ' \
                    "#{transactions.map(&:transaction_id).join(', ')}. Actual " \
                    "deleted transactions: #{deleted_ids.join(', ')}"
          Rails.logger.info(log_msg)
        end
      end

      def update_transaction_cursor(transaction_data)
        @item.update(transaction_sync_cursor: transaction_data[:next_cursor])
      end

      def fetch_transactions_data
        PlaidServices::Api.new(@item.access_key)
                          .transactions_sync(@item.transaction_sync_cursor)
      rescue Plaid::ApiError => e
        handle_api_error(e)
      end

      def handle_api_error(error)
        raise error unless error.data['error_type'] == Plaid::ApiRateLimitError::ERROR_TYPE

        raise Plaid::ApiRateLimitError
      end
    end
  end
end
