# frozen_string_literal: true

module PlaidServices
  module Transactions
    module Sync
      class AddedHandler
        def initialize(plaid_item, category_mapper, plaid_accounts)
          @item = plaid_item
          @category_mapper = category_mapper
          @plaid_accounts = plaid_accounts
        end

        def handle(transactions)
          transactions.group_by(&:account_id).each do |plaid_account_id, txns|
            account = find_or_create_account(plaid_account_id)
            next if account.nil?

            create_transactions(account, txns)
          end
        end

        private

        def create_transactions(account, transactions)
          transactions.each do |t|
            CreateService.new(account, t, category_mapper: @category_mapper).call
          rescue ActiveRecord::RecordNotUnique
            error_msg = 'Transactions::Sync attempted to create transaction with a ' \
                        "duplicate plaid_transaction_id: #{t.transaction_id} in account: " \
                        "#{account.id} and creation was skipped."
            Rails.logger.error(error_msg)
            next
          end
        end

        def find_or_create_account(id)
          account = @item.accounts.find_by(plaid_account_id: id)
          return account if account.present?

          # If account doesn't exist but we have its data, create it
          plaid_account = @plaid_accounts[id]
          if plaid_account.present?
            msg = "Creating new Plaid account #{id} discovered during " \
                  'transaction sync'
            Rails.logger.info(msg)
            return PlaidServices::Accounts::CreateService.new(@item)
                                                         .call(plaid_account)
          end

          msg = "Plaid Account #{id} not found locally and not present " \
                'in transaction sync response'
          Rails.logger.error(msg)
          nil
        rescue ActiveRecord::RecordNotFound
          msg = 'Attempted to create account with plaid_account_id: ' \
                "#{id} but it exists under another item"
          Rails.logger.error(msg)
          nil
        end
      end
    end
  end
end
