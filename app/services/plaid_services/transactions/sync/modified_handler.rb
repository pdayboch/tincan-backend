# frozen_string_literal: true

module PlaidServices
  module Transactions
    module Sync
      class ModifiedHandler
        def initialize(plaid_item, category_mapper)
          @item = plaid_item
          @category_mapper = category_mapper
        end

        def handle(transactions)
          transactions.group_by(&:account_id).each do |plaid_account_id, txns|
            account = @item.accounts.find_by(plaid_account_id: plaid_account_id)
            if account.nil?
              msg = "Plaid account: #{plaid_account_id} not found when " \
                    'attempting to modify transactions with IDs: ' \
                    "#{txns.map(&:transaction_id).join(', ')}"
              Rails.logger.error(msg)
              next
            end

            modify_transactions(account, txns)
          end
        end

        def modify_transactions(account, transactions)
          transactions.each do |t|
            ModifyService.new(account, t, category_mapper: @category_mapper).call
          rescue ActiveRecord::RecordNotFound
            error_msg = 'Transactions::Sync attempted to modify a non-existent ' \
                        "Plaid transaction: #{t.transaction_id} in account: " \
                        "#{account.id}. Modify was skipped."
            Rails.logger.error(error_msg)
            next
          end
        end
      end
    end
  end
end
