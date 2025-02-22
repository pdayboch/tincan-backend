# frozen_string_literal: true

module PlaidServices
  module Transactions
    module Sync
      class RemovedHandler
        def initialize(plaid_item)
          @item = plaid_item
        end

        def handle(transactions)
          transactions.group_by(&:account_id).each do |plaid_account_id, txns|
            account = @item.accounts.find_by(plaid_account_id: plaid_account_id)
            if account.nil?
              msg = "Plaid account: #{plaid_account_id} not found when " \
                    'attempting to remove Plaid transactions with IDs: ' \
                    "#{txns.map(&:transaction_id).join(', ')}"
              Rails.logger.error(msg)
              next
            end

            deleted_ids = RemoveService.new(account, txns).call
            log_msg = 'Plaid Transactions SyncService requested to delete: ' \
                      "#{txns.map(&:transaction_id).join(', ')}. Actual " \
                      "deleted transactions: #{deleted_ids.join(', ')}"
            Rails.logger.info(log_msg)
          end
        end
      end
    end
  end
end
