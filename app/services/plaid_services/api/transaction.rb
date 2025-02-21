# frozen_string_literal: true

module PlaidServices
  class Api
    module Transaction
      def transactions_sync(initial_cursor = nil)
        cursor = initial_cursor || ''
        original_cursor = nil
        accounts = []
        added = []
        modified = []
        removed = []
        retry_count = 0

        begin
          has_more = true
          while has_more
            response = fetch_transactions_page(cursor)

            # Set original cursor before updating cursor
            original_cursor = cursor if has_more && original_cursor.nil?

            cursor = response.next_cursor
            accounts = response.accounts if accounts.empty?
            added += response.added
            modified += response.modified
            removed += response.removed
            has_more = response.has_more
          end

          {
            next_cursor: cursor,
            accounts: accounts,
            added: added,
            modified: modified,
            removed: removed
          }
        rescue Plaid::ApiError => e
          Api.log_plaid_error(e)

          if mutation_during_pagination?(e) && !original_cursor.nil? && retry_count < MAX_RETRIES
            retry_count += 1
            accounts = []
            added = []
            modified = []
            removed = []
            cursor = original_cursor
            retry
          end

          raise e
        end
      end

      private

      def fetch_transactions_page(cursor)
        request = Plaid::TransactionsSyncRequest.new(
          access_token: @access_token,
          cursor: cursor,
          count: 500
        )
        @client.transactions_sync(request)
      end

      def mutation_during_pagination?(error)
        body = JSON.parse(error.response_body)
        body['error_code'] == MUTATION_ERROR
      end
    end
  end
end
