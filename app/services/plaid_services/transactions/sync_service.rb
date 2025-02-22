# frozen_string_literal: true

module PlaidServices
  module Transactions
    class SyncService
      def initialize(plaid_item, category_mapper: nil)
        @item = plaid_item
        @category_mapper = category_mapper || ::Plaid::CategoryMapper.new
      end

      def call
        transactions_data = fetch_transactions_data
        return if transactions_data.nil?

        plaid_accounts = transactions_data[:accounts].index_by(&:account_id)

        Sync::AddedHandler.new(@item, @category_mapper, plaid_accounts)
                          .handle(transactions_data[:added])
        Sync::ModifiedHandler.new(@item, @category_mapper)
                             .handle(transactions_data[:modified])
        Sync::RemovedHandler.new(@item).handle(transactions_data[:removed])

        @item.mark_transactions_as_synced(transactions_data[:next_cursor])
      end

      private

      def fetch_transactions_data
        PlaidServices::Api.new(@item.access_key)
                          .transactions_sync(@item.transaction_sync_cursor)
      rescue Plaid::ApiError => e
        handle_api_error(e)
      end

      def handle_api_error(error)
        case error.data['error_type']
        when Plaid::ApiRateLimitError::ERROR_TYPE
          raise Plaid::ApiRateLimitError
        end

        case error.data['error_code']
        when 'NO_ACCOUNTS'
          msg = 'Transactions::Sync - no accounts available to sync ' \
                "transactions on PlaidItem: #{@item.item_id}"
          Rails.logger.warn(msg)
          return nil
        end

        raise error
      end
    end
  end
end
